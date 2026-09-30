# RACE TV v4 // motion + auto (réplica PHIL TV)
Tower animada + auto-director de batalhas + alerta automático + auto-layout 16:9. Técnicas do CMRT-Broadcast-HUD em `lua-off`.

## Novidades v4
1. **Motor de animação** (`core/anim.lua`): `remap/ease/damp/popup` (out-quart/back/in-quad) — mesma matemática do `common/settings.lua` do CMRT.
2. **Tower com vida**: linhas deslizam ao trocar de posição (`rowY` + damp 10 + clip), caution pisca, battle outline pulsa.
3. **Auto-director** (Battle): com `Auto-batalha` ligado, os cards seguem a briga mais próxima <1.2s em vez do focado.
4. **TV Alert** (janela nova 470x64, top-center): `FASTEST LAP roxo` ao detectar overall best novo + `YELLOW FLAG` em caution, reveal por clip + fade + slide, some sozinho em ~6s. Igual `new_best_sector` do CMRT.
5. **Auto-layout** (`core/layout.lua` + botão em Settings): `ac.getAppWindows` + `accessAppWindow:move/resize` com preset 1080p proporcional à resolução real. Botão `Aplicar layout agora` + toggle por sessão.
6. Onboard/battle mantêm slide-in ao trocar focado; tags com fade por distância.
Rework a partir dos prints do seu amigo: tower preta/azul, battle cards duplos, onboard topo, telemetry topo e tags.

## O que foi replicado do PHIL TV
1. **Tower** (`widgets/tower.lua`): header preto com série gigante italic + barra azul royal com clock `H:MM:SS` (ou volta atual/total na corrida) + linhas navy + **P1 e focado em branco** + quadrado com inicial + PIT vermelho / OUT + quali mostra BEST, corrida mostra GAP + footer azul + borda cyan fina + header amarelo piscando em caution.
2. **Battle cards** (`widgets/battle.lua` NOVO, janela `TV Battle` 660x130): 2 cards lado a lado do focado vs rival (à frente, ou atrás se P1). Faixa colorida por piloto + nome + navy com POS / volta atual ou gap amarelo + best + S1 S2 S3 com setor ativo pelo spline.
3. **Onboard top** (`widgets/onboard.lua` NOVO, `TV Onboard Top` 490x60): `[POS navy] [NOME bar colorida + carro] ONBOARD` centralizado no topo, segue focado com slide.
4. **Telemetry topo** (`widgets/speed.lua` refeito, `TV Telemetry` 480x72): barra preta com POS colorido + GEAR 1-6 com atual em branco + SPEED + RPM/MPH + barra RPM vermelha topo + barra verde base + `TELEMETRY`.
5. **Tags** (`widgets/tags.lua` NOVO, sem janela): `ui.onDriverNameTag` com box navy `POS + NOME` + risca da cor do piloto, fade por distância 220m, toggle em Settings. Igual tags `ARTHUR SHELBY 5` do print.
6. Mantidos e já no padrão sólido: Inputs, Timing, Onboard Bar, Spotter.

## Cores por piloto
Hash `idx % 6`: vermelho, lima, prata, amarelo, azul, laranja — igual cards do PHIL (P1 vermelho, P2 verde, P3 cinza...).

## Posicionar (igual prints)
- Tower esquerda topo | Telemetry topo centro | Onboard Top topo centro (abaixo telemetry ou alternar) | Battle centro inferior | Spotter/Inputs/Timing conforme gosto | Tags automáticas no mundo.
- No CM ative: TV Tower, TV Battle, TV Onboard Top, TV Telemetry, TV Settings (+ opcionais).

## Limites honestos
- Sem logos de montadora (sem assets) — quadrado com inicial no lugar.
- S1/S2/S3 por spline (terços da pista), não setores oficiais.
- Gap estimado por spline (fallback CMRT).
- Mapa da pista do canto (Spa/Watkins) não incluso — precisa de spline do traçado; próximo passo.
- Starting grid splash P1-vs-P2 é overlay de pré-corrida do OBS do amigo, não do AC — replicável como cena do OBS, não como app.
