# VELOCITY SLASH // Streamer HUD
HUD broadcast único para criador de conteúdo e live no OBS — Assetto Corsa + CSP.

## Conceito (totalmente diferente)
Linguagem **SLASH**: todo painel é glass escuro + barra accent lateral + corte diagonal no topo + header `// SEU CANAL ● LIVE`.
Nenhum HUD da pasta (CMRT, F1-25, WEC, IMSA, GT7 Tags, iRacing Pedals) usa essa identidade. É pensado para leitura em 1080p no YouTube/Twitch.

## Módulos (6 janelas separadas = 6 fontes posicionáveis)
| Janela CM | Arquivo | O que mostra |
|---|---|---|
| VS Tower | `widgets/tower.lua` | Timing tower P1-P10 (configurável 5-20), gap estimado líder/à frente, tyre dot, battle highlight pulsante <1s, focus highlight |
| VS Speed Gear | `widgets/speed.lua` | Gear gigante + speed + RPM slash bar + SHIFT flash + nome do focado |
| VS Pedals | `widgets/pedals.lua` | THR/BRK slim + steering bipolar com graus — prova de pilotagem |
| VS Lap Delta | `widgets/lap.lua` | CUR/LAST/BEST + ★ overall + delta bar vs BEST |
| VS Lower Third | `widgets/lowerthird.lua` | Lower-third animado do piloto focado: P, nome, carro, status, BEST, branding canal |
| VS Radar | `widgets/radar.lua` | Radar circular 60m com orientação pelo look do carro, alerta vermelho <8m |
| VS Settings | `core/config.lua` | Nome canal, 4 accents, escala 0.7-1.6, opacidade, linhas tower, MPH |

Modo híbrido: tudo segue `sim.focusedCar`. Pilotando mostra YOU. Transmitindo, troca com PageUp/PageDown ou click e todos os widgets seguem.

## Instalação
1. Pasta já está em `apps/lua/Streamer Hud` com `Streamer Hud.lua` (nome == pasta, obrigatório CSP).
2. Abra Content Manager > Settings > Custom Shaders Patch > Apps > ative:
   - VS Tower, VS Speed Gear, VS Pedals, VS Lap Delta, VS Lower Third, VS Radar, VS Settings
3. Entre na pista, abra menu lateral de Apps (passar mouse na direita), posicione cada janela:
   - Tower esquerda, Lap topo-direita, Speed inferior-direita, Pedals inferior-centro, Lower-Third inferior-esquerda, Radar acima do Speed.
4. VS Settings > digite nome do canal + escolha accent. Salva automático via `ac.storage`.

## OBS
- Use **Game Capture** do AC (HUD desenha dentro do jogo, sem janela externa).
- Desative sombra dos apps no CM para look clean.
- Para cinematic: opacidade 0.6 + escala 0.9. Para destaque: opacidade 1.0.
- LIVE dot pulsa sozinho — ótimo gatilho visual de "ao vivo".
- Plugin opcional `acc-obs-plugin` permite separar HUD em textura limpa se quiser compor no OBS.

## Referências pesquisadas
- Locais: `CMRT-Complete-HUD` (30+ módulos, gaps por spline), `F1-25` (arquitetura modular + monoespaçado), `WEC_HUD_2026` (tower TV + focusCar + classes), `FSH_IMSA_HUD_26` (multiclasse), `GT7DriverTags` (tags 3D adjacentes), `iRacing-Pedals-HUD` (pedals + telemetry graph).
- Web: Track Impulse overlays, RaceLab overlays, ACTV Graphics Suite, CMRT Broadcast HUD, WEC 2025 nova identidade TV (sidebar + sector colors + brand colors), OBS CSP plugin (`shared/utils/obs`).

## Estrutura
```
Streamer Hud/
  manifest.ini
  Streamer Hud.lua
  icon.png
  core/config.lua  (settings persistentes)
  core/draw.lua    (slashPanel, header, hbar, fmtLap/Gap, tyreColor)
  widgets/tower.lua / speed.lua / pedals.lua / lap.lua / lowerthird.lua / radar.lua
```

## Limitações honestas V1
- Gap é **estimado** por `splinePosition + lapCount` (mesma técnica fallback do CMRT). Em multiclasse/online com volta de diferença mostra `+1 LAP`.
- Sem assets externos (fonte/imagem) de propósito: zero-dependência, funciona em qualquer resolução.
- Próximos passos: tyre real via extended physics, battle detector com som, auto-director, ticker inferior, presets OBS 16:9/21:9 em 1 clique.

## Teste
- Sintaxe validada com `lupa LuaRuntime.compile` em todos os 9 .lua.
- Para validar no jogo: CM > Drive > ative apps > confira console CSP sem `VS ERROR`.
