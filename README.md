# Util_fs - библиотека для elixir приложений

FS поддержка:
 * minio

## Установка
In mix.exs file
```elixir
# в список приложений, которые должны быть запущены
applications: [ ..., :util_fs]

# добавить в зависимости
def deps do
  [{:util_fs, git: "git@git.it.tender.pro:bot/util_fs.git"}]
end
```

## Применение
Настройка config.exs для FS

```elixir
config :util_fs,
  options: %{
    fs: %{
      fs_type: :minio
    }
  }
```
