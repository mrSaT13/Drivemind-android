# Датасет — почему здесь только сэмпл

В портфолио-версии специально лежит урезанный набор:
- `questions.json` — билет №1, 20 вопросов (в полном — 800, билеты 1–40)
- `signs.json` — 8 знаков (в полном — 310)
- `questions_kids.json` — 10 детских (в полном — 200)
- `assets/images/` — 21 файл, только те, на которые ссылается сэмпл

Причины:
1. Размер: полный пак — ~15 МБ / 852 картинки, рекрутеру это не нужно.
2. Права: полные билеты/картинки исторически связаны с github.com/etspring/pdd_russia
   (без LICENSE-файла) — см. `NOTICE.md`. Для портфолио безопаснее показывать сэмпл
   с атрибуцией, а не полный дамп.

## Как восстановить полный датасет локально (не для пуша)
```bash
# из корня основного проекта:
python3 -c "import json; print(len(json.load(open('assets/data/questions.json'))))"
cp assets/data/questions.json "на портфолио/assets/data/questions.json"
cp assets/data/signs.json "на портфолио/assets/data/signs.json"
cp assets/data/questions_kids.json "на портфолио/assets/data/questions_kids.json"
cp assets/images/* "на портфолио/assets/images/"
```
Не коммить полный датасет в публичное портфолио-репо без разрешения автора источника
или замены на официальные тексты + свои картинки.
