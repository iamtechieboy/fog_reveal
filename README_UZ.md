# fog_reveal

Flutter’dagi rasm, card yoki istalgan widgetni organik tuman orqali ochib
beradigan yengil shader paketi.

## Ko‘rinishi

| Organik reveal | Custom stillar |
| :---: | :---: |
| ![Flutter card ustidagi organik fog reveal](screenshots/fog_reveal_demo.png) | ![Demo, dark va mist fog stillari](screenshots/fog_reveal_styles.png) |

## O‘rnatish

```sh
flutter pub add fog_reveal
```

```dart
import 'package:fog_reveal/fog_reveal.dart';
```

Shader paket bilan birga keladi. Ilova `pubspec.yaml` fayliga alohida shader
asset qo‘shish shart emas.

## Eng sodda ishlatish

```dart
AnimatedFogReveal(
  borderRadius: BorderRadius.circular(24),
  child: Image.network(imageUrl, fit: BoxFit.cover),
)
```

Controller berilmasa, shader tayyor bo‘lgach animatsiya avtomatik boshlanadi.
Default qiymatlar reference demodagidek: 2800 ms, `easeInOutCubic`,
`Color(0xFFF0F2F2)`, 0.1 softness, 6 drift, 1709 seed va 256 px texture.

## Image loader bilan

Ishlatayotgan image loader yoki cache kutubxonangiz bergan loaded holatini
`revealed`ga ulang:

```dart
AnimatedFogReveal(
  revealed: imageLoaded,
  duration: const Duration(milliseconds: 1200),
  style: FogStyle.lightweight,
  borderRadius: BorderRadius.circular(20),
  child: image,
)
```

`revealed: true` joriy joydan reveal qiladi, `false` esa silliq yopadi. Child
animatsiya davomida mounted holatda qoladi.

`revealed`, `duration`, `reverseDuration` va `initialProgress` faqat ichki
controller ishlatilganda amal qiladi. Tashqi `controller` berilsa, playbackni
o‘sha controller boshqaradi.

## Custom ko‘rinish

```dart
const style = FogStyle(
  color: Color(0xD9E8F7FF),
  softness: 0.16,
  drift: 4,
  seed: 42,
  textureSize: 128,
);
```

- `color` — tuman rangi; alpha maksimal shaffoflikni belgilaydi.
- `softness` — erish chegarasining yumshoqligi, 0 dan katta va 0.5 gacha.
- `drift` — bulut harakati, -1000 dan 1000 gacha; 0 harakatni to‘xtatadi.
- `seed` — takrorlanuvchi noise naqshi.
- `textureSize` — 16–512 oralig‘idagi noise texture o‘lchami.

Presetlar: `FogStyle.demo`, `FogStyle.light`, `FogStyle.dark`, `FogStyle.mist`
va list/gridlar uchun 128 px `FogStyle.lightweight`. `copyWith` orqali faqat
kerakli qiymatni almashtirish mumkin.

## Repeat

```dart
AnimatedFogReveal(
  loop: true,
  child: yourWidget,
)
```

`loop: true` tumandan ochilish animatsiyasini uzluksiz takrorlaydi. `false`
qilinganda joriy sikl oxirigacha boradi. Ichki controllerda `revealed: false`
bo‘lsa loop ishlamaydi.

Loop `AnimationController.repeat()` orqali ishlaydi. Shu sabab `onEnd` har bir
loop siklida chaqirilmaydi; u oddiy reveal yoki cover endpointga yetganda
chaqiriladi.

## Controller bilan boshqarish

Replay, slider, pause yoki imperative boshqaruv kerak bo‘lsa:

```dart
late final fog = FogRevealController(vsync: this);

AnimatedFogReveal(
  controller: fog,
  onReady: fog.replay,
  child: yourWidget,
)

@override
void dispose() {
  fog.dispose();
  super.dispose();
}
```

Controllerda `reveal`, `cover`, `replay`, `pause`, `resume`, `seek`, `toggle`
va standart `repeat` mavjud. Tashqi controllerni yaratgan `State` uni dispose
qilishi kerak.

`loop: true` tashqi controller bilan ham ishlaydi va shader tayyor bo‘lgach
o‘zi boshlanadi. Widget olib tashlansa yoki controller almashtirilsa, widget
boshlagan repeat to‘xtatiladi, lekin controller dispose qilinmaydi.

## Past darajadagi API

Progressni bevosita berish uchun:

```dart
FogReveal(progress: progress, child: yourWidget)
```

Istalgan `Animation<double>` bilan:

```dart
FogTransition(animation: animation, child: yourWidget)
```

## Muhim behavior va performance

- Shader tayyor bo‘lguncha yoki load xatosida child fog’siz ko‘rinadi.
- `onReady` birinchi load va `seed`/`textureSize` muvaffaqiyatli yangilanganda
  chaqiriladi. Texture reload tugagan animatsiyani qayta boshlamaydi.
- `blockInteraction` pointer inputni, `excludeSemantics` accessibility
  ma’lumotini widget to‘liq ochilguncha bloklaydi.
- Bir xil `seed` va `textureSize` ishlatgan faol widgetlar bitta noise teksturani
  bo‘lishadi. Rang, softness yoki drift o‘zgarishi yangi texture yaratmaydi.
- Katta list/grid uchun 64 yoki 128 px texture tavsiya qilinadi. `seed`ni har
  frame almashtirmang.
- 256 px RGBA texture taxminan 256 KiB, 128 px esa 64 KiB xotira ishlatadi
  (engine overhead’dan tashqari).
- Unbounded parent ichida childga aniq o‘lcham bering.

Minimal talab: Flutter 3.27+ va Dart 3.6+.

To‘liq misol: [`example/lib/main.dart`](example/lib/main.dart).
