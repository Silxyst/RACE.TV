# ENDURO TV // Streamer HUD v2
Broadcast **sólida** estilo IMSA / WEC / NLS para live no OBS. Refeito do zero após feedback: sem glass, sem neon, sem slash — 100% TV.

## O que mudou da v1 (Velocity Slash)
- Removido: painéis glass arredondados, barra neon, corte diagonal, LIVE dot, canal obrigatório.
- Novo: retângulos chapados com gradiente TV (cor cheia → 55% escuro), tipografia **Archivo Italic Bold** real (copiada da NLS), header com cor de bandeira (amarelo pisca em caution), linhas navy alternadas, tyre dot quadrado, overall best roxo ★, faixa ONBOARD navy + número gigante.

## Módulos (renomeados, mesmas janelas)
| Janela CM | Tamanho | Estilo |
|---|---|---|
| ETV Tower | 310x600 | Header serie+sessão/flag + linhas P/NOME/GAP + tyre square + focus bar + battle outline |
| ETV Onboard Telemetry | 310x160 | Header ONBOARD+piloto + RPM top bar + GEAR gigante + SPEED + THR/BRK |
| ETV Inputs | 310x140 | THR/BRK/STR sólidos pit-wall |
| ETV Timing | 310x170 | CUR/LAST/BEST + delta bar sólida |
| ETV Onboard Bar | 470x100 | Barra brand + POS gigante + nome + carro + faixa ONBOARD navy |
| ETV Spotter | 200x220 | Box navy + anéis + dots (vermelho <8m) |
| ETV Settings | — | Preset Race Red / Enduro Blue / NLS Green + sigla série + escala + linhas + tyre + MPH |

Tudo segue `sim.focusedCar` (híbrido piloto/transmissão).

## Fontes
`fonts/` com Archivo-ExtraBoldItalic / BoldItalic / SemiBoldItalic / OpenSans-SemiBold (das mesmas famílias usadas por WEC/IMSA/NLS). Uso via `ui.pushDWriteFont('fonts/...')` relativo ao app.

## Cores
- Navy #0F053C, Dark #12121A/#1C1C26, Race Red #E10600, Enduro Blue #006EFF, NLS Green #00B450, Yellow #FFD700, Green #00B432, Purple ★ #BE5AFF.

## Instalar / posicionar
1. CM > CSP > Apps > ative os 7 ETV.
2. Posicione: Tower esquerda | Timing topo-direita | Telemetry inf-direita | Inputs inf-centro | Onboard Bar inf-esquerda | Spotter acima Telemetry.
3. ETV Settings > preset + sigla (ex: IMSA, WEC, NLS).

## Notas honestas
- Gap estimado por spline (fallback CMRT). Mostra +1 LAP com volta de diferença.
- Sem logos de marcas (evita asset pesado); número exibido = POS.
- Sintaxe validada via lupa em 9 .lua.
