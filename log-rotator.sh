#!/bin/bash

# log-rotator.sh
# Автоматическая ротация и архивация логов старше N дней
# Автор: Ilyas

set -euo pipefail

# === Конфигурация ===
LOG_DIR="${LOG_DIR:-/var/log/myapp}"
ARCHIVE_DIR="${ARCHIVE_DIR:-/var/log/archive}"
DAYS_TO_KEEP="${DAYS_TO_KEEP:-7}"
DATE=$(date +%Y%m%d_%H%M%S)

# === Функции ===

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

create_dirs() {
  mkdir -p "$ARCHIVE_DIR"
}

rotate_logs() {
  log "Проверка директории логов: $LOG_DIR"
  if [ ! -d "$LOG_DIR" ]; then
    log "Директория $LOG_DIR не существует. Пропускаем ротацию."
    return 0
  fi

  # Находим .log файлы старше DAYS_TO_KEEP дней
  while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
      log "Архивация: $file"
      gzip -c "$file" > "$ARCHIVE_DIR/$(basename "$file").$DATE.gz"
      rm -f "$file"
    fi
  done < <(find "$LOG_DIR" -type f -name "*.log" -mtime +$DAYS_TO_KEEP -print0)
}

cleanup_old_archives() {
  log "Очистка архивов старше 30 дней в: $ARCHIVE_DIR"
  find "$ARCHIVE_DIR" -type f -name "*.gz" -mtime +30 -delete 2>/dev/null || true
}

# === Основной запуск ===
main() {
  log "=== Запуск log-rotator ==="
  create_dirs
  rotate_logs
  cleanup_old_archives
  log "=== Ротация завершена ==="
}

main "$@"
