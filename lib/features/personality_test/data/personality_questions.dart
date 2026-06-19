import '../models/personality_question.dart';

const personalityCategoryLabels = {
  'social': 'Sosyallik',
  'curiosity': 'Öğrenme Merakı',
  'emotional': 'Duygusal Zeka',
  'discipline': 'Disiplin',
  'interests': 'İlgi Alanları',
};

const personalityQuestions = [
  PersonalityQuestion(
    id: 1,
    text: 'Yeni insanlarla tanışmak beni heyecanlandırır.',
    category: 'social',
  ),
  PersonalityQuestion(
    id: 2,
    text: 'Kalabalık ortamlarda enerjim yükselir.',
    category: 'social',
  ),
  PersonalityQuestion(
    id: 3,
    text: 'Uzun süre yalnız kalmaktan hoşlanırım.',
    category: 'social',
    reverseScored: true,
  ),
  PersonalityQuestion(
    id: 4,
    text: 'İnsanlarla fikir alışverişi yapmak beni motive eder.',
    category: 'social',
  ),
  PersonalityQuestion(
    id: 5,
    text: 'Bir grupta genellikle konuşmayı başlatan kişi olurum.',
    category: 'social',
  ),
  PersonalityQuestion(
    id: 6,
    text: 'Düşüncelerimi başkalarıyla paylaşmakta rahat hissederim.',
    category: 'social',
  ),
  PersonalityQuestion(
    id: 7,
    text: 'Bilmediğim konuları araştırmaktan keyif alırım.',
    category: 'curiosity',
  ),
  PersonalityQuestion(
    id: 8,
    text: 'Belgesel, eğitim videoları veya bilgi içerikleri ilgimi çeker.',
    category: 'curiosity',
  ),
  PersonalityQuestion(
    id: 9,
    text: 'Yeni beceriler öğrenmek için zaman ayırırım.',
    category: 'curiosity',
  ),
  PersonalityQuestion(
    id: 10,
    text: 'Farklı kültürler ve yaşam tarzları hakkında bilgi edinmek isterim.',
    category: 'curiosity',
  ),
  PersonalityQuestion(
    id: 11,
    text: 'Karmaşık problemleri çözmek hoşuma gider.',
    category: 'curiosity',
  ),
  PersonalityQuestion(
    id: 12,
    text: '"Nasıl çalışıyor?" sorusunu sık sık sorarım.',
    category: 'curiosity',
  ),
  PersonalityQuestion(
    id: 13,
    text: 'Duygularım kararlarımı etkiler.',
    category: 'emotional',
  ),
  PersonalityQuestion(
    id: 14,
    text: 'Başkalarının hislerini kolayca anlayabilirim.',
    category: 'emotional',
  ),
  PersonalityQuestion(
    id: 15,
    text: 'Eleştiriler beni uzun süre etkiler.',
    category: 'emotional',
  ),
  PersonalityQuestion(
    id: 16,
    text: 'Empati kurmanın önemli olduğunu düşünürüm.',
    category: 'emotional',
  ),
  PersonalityQuestion(
    id: 17,
    text: 'Duygusal hikayeler beni etkiler.',
    category: 'emotional',
  ),
  PersonalityQuestion(
    id: 18,
    text: 'Çevremdeki insanların ruh halini fark ederim.',
    category: 'emotional',
  ),
  PersonalityQuestion(
    id: 19,
    text: 'Kendime hedef koyduğumda onu tamamlamak için uğraşırım.',
    category: 'discipline',
  ),
  PersonalityQuestion(
    id: 20,
    text: 'Planlı hareket etmeyi severim.',
    category: 'discipline',
  ),
  PersonalityQuestion(
    id: 21,
    text: 'Ertelemeyi sık yaparım.',
    category: 'discipline',
    reverseScored: true,
  ),
  PersonalityQuestion(
    id: 22,
    text: 'Sorumluluklarımı zamanında yerine getiririm.',
    category: 'discipline',
  ),
  PersonalityQuestion(
    id: 23,
    text: 'Uzun vadeli hedefler belirlemek benim için önemlidir.',
    category: 'discipline',
  ),
  PersonalityQuestion(
    id: 24,
    text: 'Bir işe başladığımda bitirmeye çalışırım.',
    category: 'discipline',
  ),
  PersonalityQuestion(
    id: 25,
    text: 'Sanat, müzik veya yaratıcı aktiviteler ilgimi çeker.',
    category: 'interests',
  ),
  PersonalityQuestion(
    id: 26,
    text: 'Teknoloji ve yenilikleri takip ederim.',
    category: 'interests',
  ),
  PersonalityQuestion(
    id: 27,
    text: 'Spor veya fiziksel aktiviteler hayatımda yer alır.',
    category: 'interests',
  ),
  PersonalityQuestion(
    id: 28,
    text: 'Finans, yatırım veya para yönetimi konularına ilgi duyarım.',
    category: 'interests',
  ),
  PersonalityQuestion(
    id: 29,
    text: 'Psikoloji ve insan davranışları ilgimi çeker.',
    category: 'interests',
  ),
  PersonalityQuestion(
    id: 30,
    text: 'Girişimcilik ve iş kurma hikayelerini severim.',
    category: 'interests',
  ),
];
