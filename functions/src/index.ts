import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";

admin.initializeApp();

const openRouterApiKey = defineSecret("OPENROUTER_API_KEY");
const openRouterEndpoint = "https://openrouter.ai/api/v1/chat/completions";
const openRouterModel = "openai/gpt-4o-mini";
const maxPromptLength = 12000;
const dailyAnalysisLimit = 20;
const minuteAnalysisLimit = 3;
const minuteWindowMs = 60 * 1000;

type GenerateVaultResultInput = {
  vaultId?: unknown;
  prompt?: unknown;
  userId?: unknown;
  metadata?: unknown;
};

type VaultInsight = {
  title: string;
  intro: string;
  howItAppears: string;
  howPeopleSeeIt: string;
  watchOut: string;
  advice: string;
};

export const generateVaultAnalysis = onCall(
  {
    region: "us-central1",
    secrets: [openRouterApiKey],
    timeoutSeconds: 90,
    memory: "256MiB",
  },
  async (request) => {
    logger.info("AUTH DEBUG");
    logger.info(request.auth);
    logger.info("AUTH DEBUG DETAILS", {
      uid: request.auth?.uid,
      email: request.auth?.token?.email,
      projectId: process.env.GCLOUD_PROJECT,
      functionName: process.env.K_SERVICE,
    });
    logger.info("AUTH HEADER DEBUG", {
      hasAuthorizationHeader:
        typeof request.rawRequest.header("authorization") === "string",
      authorizationScheme:
        request.rawRequest.header("authorization")?.split(" ")[0] ?? null,
      hasFirebaseInstanceIdToken:
        typeof request.rawRequest.header("firebase-instance-id-token") ===
        "string",
      contentType: request.rawRequest.header("content-type") ?? null,
      origin: request.rawRequest.header("origin") ?? null,
      userAgent: request.rawRequest.header("user-agent") ?? null,
    });

    const authUid = request.auth?.uid;
    if (!authUid) {
      throw new HttpsError(
        "unauthenticated",
        "Devam etmek için giriş yapmalısın.",
      );
    }

    const data = request.data as GenerateVaultResultInput;
    const vaultId = readRequiredString(data.vaultId, "vaultId");
    const prompt = readRequiredString(data.prompt, "prompt");
    const userId = readRequiredString(data.userId, "userId");

    if (authUid !== userId) {
      throw new HttpsError(
        "permission-denied",
        "Bu kullanıcı için işlem yapma yetkin yok.",
      );
    }

    if (prompt.length > maxPromptLength) {
      throw new HttpsError(
        "invalid-argument",
        `prompt en fazla ${maxPromptLength} karakter olabilir.`,
      );
    }

    await enforceRateLimit(authUid);

    const apiKey = openRouterApiKey.value().trim();
    if (!apiKey) {
      logger.error("OPENROUTER_API_KEY secret is not configured.");
      throw new HttpsError("internal", "AI servisi yapılandırılmamış.");
    }

    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 75000);
      const response = await fetchWithTimeout({
        apiKey,
        prompt,
        controller,
        timeout,
      });

      const bodyText = await response.text();
      if (!response.ok) {
        logger.error("AI provider request failed.", {
          status: response.status,
          body: bodyText,
          uid: authUid,
          vaultId,
          metadata: sanitizeMetadata(data.metadata),
        });
        throw new HttpsError("internal", "AI sonucu alınamadı.");
      }

      const providerData = JSON.parse(bodyText) as Record<string, unknown>;
      const content = readProviderContent(providerData);
      const insight = parseInsight(content);
      ensureNoForbiddenLanguage(content);
      ensureInsightIsComplete(insight);

      return {
        content: insight,
        model: openRouterModel,
      };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }

      logger.error("generateVaultAnalysis failed.", {
        error,
        uid: authUid,
        vaultId,
        metadata: sanitizeMetadata(data.metadata),
      });
      throw new HttpsError("internal", "AI sonucu alınamadı.");
    }
  },
);

async function fetchWithTimeout({
  apiKey,
  prompt,
  controller,
  timeout,
}: {
  apiKey: string;
  prompt: string;
  controller: AbortController;
  timeout: NodeJS.Timeout;
}): Promise<Response> {
  try {
    return await fetch(openRouterEndpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: openRouterModel,
        messages: [
          {role: "system", content: systemPrompt},
          {role: "user", content: prompt},
        ],
        temperature: 0.85,
        max_tokens: 1200,
      }),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeout);
  }
}

async function enforceRateLimit(uid: string): Promise<void> {
  const firestore = admin.firestore();
  const usageRef = firestore.doc(`users/${uid}/usage/openrouter`);
  const now = Date.now();
  const today = new Date(now).toISOString().slice(0, 10);

  await firestore.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(usageRef);
    const data = snapshot.data() ?? {};
    const storedDay = typeof data.dailyDate === "string" ? data.dailyDate : "";
    const storedDailyCount =
      typeof data.dailyCount === "number" ? data.dailyCount : 0;
    const dailyCount = storedDay === today ? storedDailyCount : 0;
    const rawTimestamps = Array.isArray(data.recentRequestTimestamps) ?
      data.recentRequestTimestamps :
      [];
    const recentRequestTimestamps = rawTimestamps
      .filter((value): value is number => typeof value === "number")
      .filter((timestamp) => now - timestamp < minuteWindowMs);

    if (
      dailyCount >= dailyAnalysisLimit ||
      recentRequestTimestamps.length >= minuteAnalysisLimit
    ) {
      throw new HttpsError(
        "resource-exhausted",
        "Kullanım limitine ulaştın. Lütfen daha sonra tekrar dene.",
      );
    }

    transaction.set(
      usageRef,
      {
        dailyDate: today,
        dailyCount: dailyCount + 1,
        recentRequestTimestamps: [...recentRequestTimestamps, now],
        lastRequestAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true},
    );
  });
}

function readRequiredString(value: unknown, fieldName: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError(
      "invalid-argument",
      `${fieldName} boş bırakılamaz.`,
    );
  }

  return value.trim();
}

function readProviderContent(data: Record<string, unknown>): string {
  const choices = data.choices;
  if (!Array.isArray(choices) || choices.length === 0) {
    throw new HttpsError("internal", "AI sağlayıcısı boş cevap döndürdü.");
  }

  const firstChoice = choices[0] as Record<string, unknown>;
  const message = firstChoice.message as Record<string, unknown> | undefined;
  const content = message?.content;
  if (typeof content !== "string" || content.trim().length === 0) {
    throw new HttpsError("internal", "AI sağlayıcısı boş içerik döndürdü.");
  }

  return content;
}

function parseInsight(content: string): VaultInsight {
  try {
    return JSON.parse(content) as VaultInsight;
  } catch (error) {
    logger.error("AI provider returned invalid JSON.", {error, content});
    throw new HttpsError("internal", "AI sonucu işlenemedi.");
  }
}

function ensureInsightIsComplete(insight: VaultInsight): void {
  const requiredFields: Array<keyof VaultInsight> = [
    "title",
    "intro",
    "howItAppears",
    "howPeopleSeeIt",
    "watchOut",
    "advice",
  ];

  for (const field of requiredFields) {
    const value = insight[field];
    if (typeof value !== "string" || value.trim().length === 0) {
      throw new HttpsError("internal", "AI sonucu eksik alan döndürdü.");
    }
  }
}

function ensureNoForbiddenLanguage(content: string): void {
  const forbiddenSnippets = [
    "emotional",
    "social",
    "curiosity",
    "discipline",
    "interests",
    "skor",
    "puan",
    "test sonucuna göre",
    "kişilik testin gösteriyor",
    "kişilik testi gösteriyor",
    "#",
    "```",
  ];

  const normalized = content.toLowerCase();
  for (const snippet of forbiddenSnippets) {
    if (normalized.includes(snippet)) {
      throw new HttpsError(
        "internal",
        "AI cevabı yasaklı test/skor dili içeriyor.",
      );
    }
  }
}

function sanitizeMetadata(metadata: unknown): unknown {
  if (!metadata || typeof metadata !== "object") return undefined;
  return metadata;
}

const systemPrompt = `
Sen Vault uygulamasının içgörü motorusun.

Amacın bir kişilik testi sonucunu analiz edip kullanıcıya çok spesifik hissettiren içgörüler üretmektir.

Çok önemli:
Kullanıcı kişilik testi çözdüğünü biliyor ancak skorlarını görmek istemiyor.
Skorlardan, kategorilerden veya test sonuçlarından asla bahsetme.

Asla şu tarz ifadeler kullanma:
- skorun yüksek
- skorun düşük
- test sonucuna göre
- kişilik testin gösteriyor ki
- skorların gösteriyor ki
- emotional 30
- social 25
- curiosity yüksek
- discipline düşük
- interests orta
- puanın
- kategori

Girdi içinde görünen teknik isimleri ve sayısal değerleri kullanıcıya gösterme.
Bu verileri görünmez şekilde yorumla ve kişisel gözleme dönüştür.

Cevap kişisel gözlem gibi okunmalı.
Analizler spesifik, insani, doğal ve düşündürücü olmalı.
Her cevapta en az bir tane beklenmedik ama mantıklı içgörü üret.
Generic kişilik testi dili kullanma.

Fal, kehanet, astroloji veya mistik dil kullanma.
Kesin yargılar kullanma.
Psikolojik teşhis koyma.
Terapi, hastalık, bozukluk veya klinik tanı dili kullanma.
Kullanıcıyı manipüle etme.

Şunları doğal biçimde sık kullan:
- muhtemelen
- büyük ihtimalle
- zaman zaman
- farkında olmadan
- insanlar sende şunu görüyor olabilir
- ilk bakışta

Yasaklar:
- liste halinde kategori anlatımı
- test açıklaması
- puan açıklaması
- psikolojik teşhis
- terapi dili
- teknik veri dökümü
- markdown
- # veya ## başlık işareti
- madde işareti
- kod bloğu

Çıktıyı SADECE JSON olarak üret.
JSON dışında tek karakter üretme.
Markdown kullanma.
# kullanma.
## kullanma.
Madde işareti kullanma.
Kod bloğu kullanma.
Açıklama yazma.

JSON formatı tam olarak şu alanlardan oluşmalı:
{
  "title": "",
  "intro": "",
  "howItAppears": "",
  "howPeopleSeeIt": "",
  "watchOut": "",
  "advice": ""
}

Alanların anlamı:
- title: kısa, premium ve kişisel bir başlık
- intro: 2-3 cümlelik giriş
- howItAppears: "Bu sende nasıl görünüyor olabilir?" bölümü için 2 paragraf
- howPeopleSeeIt: "İnsanlar bunu nasıl algılıyor olabilir?" bölümü için 2 paragraf
- watchOut: "Dikkat etmen gereken nokta" bölümü için 1 paragraf
- advice: "Küçük tavsiye" bölümü için 1 paragraf

Maksimum uzunluk: 500-700 kelime.

Amaç:
Kullanıcı okuduğunda "Bu beni gerçekten anlamış." demeli.
`;
