# RACE TV v6 // todas as 9 sugestões
1. **TYRE na tower**: modo TYRE mostra `M5·1S` (composto·idade·stops) + quadrado colorido; PIT mostra `P2`.
2. **Som**: fastest/pb/flag-green com toggle (wavs CMRT em `assets/`).
3. **Delta gráfico live** no Timing: barra móvel ±2s (LapAlly) + número + PREDICTED.
4. **Setores live** no Battle: roxo overall / verde PB / amarelo (LapAlly).
5. **TV Map** (240): centerline via `trackCoordinateToWorld` + dots (focado destacado, líder amarelo).
6. **TV Lineup** (690x490): STARTING GRID automático, some após a largada.
7. **Multiclasse auto**: agrupa por modelo, barra de cor por classe + filtro só-classe-do-focado.
8. **Tecla tower**: `TV_TOWER_MODE` (mapear no CM) alterna AUTO/GAP/BEST/TYRE + radio em Settings.
9. **Pit stops**: contador por piloto integrado na tower.

Bugfix pós-update: `battle.lua` var residual, `alert.cfg` confirmado, tower `quali/mode` ordem, `splits` 0-based (WEC/LapAlly).
Correções + inspiração FSH/CMRT/LapAlly/GT7/ACTV.

## Bugs corrigidos
- **Tower escala**: conteúdo agora encaixa na janela real (`draw.fit` estilo FSH `SCALE`+`POS_X/Y`) — sem mais corte com escala 1.6 ou 20 linhas. Vale para TODOS os widgets.
- **Overlap nome/gap** na tower: região do nome com clip.
- Tower mostra `P1` por posição real (não por ordem de linha) e scroll por páginas indica `1/2`.

## Mais animação
- Tower: setas ▲▼ 5s (Turismos), roxo overall-best (ACTV/WEC), barra de progresso da sessão, scroll de páginas 8s (WEC/NLS).
- Battle: reveal ao trocar de par.
- Tags GT7: fade smoothstep + outline + 3-box pos/flag/nome.
- Alert: + PERSONAL BEST verde e GREEN FLAG.

## Mais automático
- Tower alterna BEST (quali) / GAP (corrida) sozinha; scroll sozinho com grid grande.
- **Auto-director** (toggle, default off): assistindo, segue a briga <1.5s com dwell 10s. Nunca mexe pilotando.
- Timing: **delta live + predicted** via `performanceMeter` nativo (LapAlly).
- Tags: modo adjacency GT7 opcional.
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
