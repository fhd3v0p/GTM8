import re

# Открываем файл
with open("/mnt/data/логи.rtf", "r", encoding="utf-8", errors="ignore") as f:
    text = f.read()

pairs = []

# Поиск пар в одной строке
for line in text.splitlines():
    m_id = re.search(r"id=(\d+)", line)
    m_ref = re.search(r"ref=([A-Z0-9]+)", line)
    if m_id and m_ref:
        uid = m_id.group(1)
        ref = m_ref.group(1)
        pairs.append((ref, uid))

# Если в одной строке не нашли — ищем в соседних
if not pairs:
    lines = text.splitlines()
    for i in range(len(lines)):
        window = "\n".join(lines[max(0, i - 1): i + 2])
        m_id = re.search(r"id=(\d+)", window)
        m_ref = re.search(r"ref=([A-Z0-9]+)", window)
        if m_id and m_ref:
            pairs.append((m_ref.group(1), m_id.group(1)))

# Убираем дубликаты и сортируем по ref
pairs = sorted(set(pairs), key=lambda x: x[0])

# Возвращаем результат как текст
result_text = "\n".join(f"{ref},{uid}" for ref, uid in pairs)
result_text[:1000]  # Покажем первые 1000 символов, чтобы не перегрузить вывод

