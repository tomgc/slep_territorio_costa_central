# 50_locale_utf8.md — Marcador del invariante de entorno

**Fecha de instalacion:** 2026-08-02

## Que se instalo

La guarda `asegurar_locale_utf8()`, que garantiza que ningun proceso de R de
este proyecto corra con una locale de caracteres no UTF-8, ni lance procesos
hijos que lo hagan.

- Archivo: `10_utils/10_locale.R`.
- Origen: `herramientas_dev/plantillas/10_locale.R`, copiado **identico**.
- md5 de la plantilla al momento de copiar: `b193041b45c883ea76b57cda66a19f9c`.
- Punto de invocacion: primera linea ejecutable de
  `10_utils/10_configuracion.R`, antes de cualquier lectura o escritura.

## Por que importa

Un proceso de R sin locale UTF-8 escribe todo texto acentuado escapado como
`<c3><a1>` (xlsx, json, html) sin emitir error alguno. El defecto no es que la
locale este mal: es que nadie se entera. La guarda tiene tres salidas y ninguna
silenciosa: retorna si ya es UTF-8, corrige avisando por `message()`, o aborta
con `stop()` nombrando la locale, las candidatas probadas y el remedio.

La guarda ademas **exporta** `LANG` y `LC_CTYPE` al entorno cuando vienen
vacios, para que los procesos hijos (`quarto`, `system2`, el R que quarto
levanta para los chunks de un `.qmd`) no arranquen en `C`.

## Reglas que rigen este archivo

- `10_utils/10_locale.R` **nunca se edita por proyecto**. Si este proyecto
  necesitara algo distinto, el helper esta mal disenado y se corrige en la
  plantilla de `herramientas_dev`.
- Prohibido envolver `Sys.setlocale()` en `try(..., silent = TRUE)` o en
  `suppressWarnings()`.

## Efecto de este marcador

La presencia de este archivo **apaga el gatillo 4ter** de
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` §1.2.2: el pendiente del invariante de
entorno deja de declararse en el acuse de apertura de cada sesion.

## Norma aplicable

`POLITICA_PROYECTO.md` v5.6 §5.2bis (invariante de entorno) y
`SETTINGS_Y_PROMPTS_OPERACIONALES.md` v16 §1.2.2 paso 4ter.

Verificable con `plantillas/90_verificar_locale.R` de `herramientas_dev`:
V1 archivo identico a la plantilla, V2 invocacion como primera linea
ejecutable, V3 comportamiento real bajo `LC_ALL=C`.
