<p align="center">
  <img src="docs/banner.svg" alt="RACE TV — Streamer HUD" width="100%">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-12.3.0-e10600?style=for-the-badge" alt="versão">
  <img src="https://img.shields.io/badge/Assetto%20Corsa-CSP%20Lua-orange?style=for-the-badge" alt="CSP Lua">
  <img src="https://img.shields.io/badge/tests-76%20passing-00b450?style=for-the-badge" alt="testes">
  <img src="https://img.shields.io/badge/OBS-redirect-1c37b4?style=for-the-badge" alt="OBS">
  <img src="https://img.shields.io/badge/Real%20Penalty-ready-ffd500?style=for-the-badge" alt="Real Penalty">
</p>

<p align="center"><b>HUD de transmissão para Assetto Corsa + CSP.</b> Torre, batalhas, delta, combustível, sessão, bandeiras, resultados e painel do narrador — cada elemento numa <b>janela real</b> pronta para o <b>OBS Apps Redirection</b> (<i>Extra: Redirected apps (transparent)</i>).</p>

---

## ✨ Destaques

| | |
|---|---|
| 🏁 | **Timing Tower estilo broadcast** — Pos · Piloto · Pneu · Volta · ΔPos · Int · Last, paginação estável, clique para focar |
| ⚔️ | **Battle + comparação manual** — dupla automática ou A/B, última volta, média e tendência |
| 📊 | **Delta, Relative, Timing e Fuel** dedicados para o piloto focado |
| 🏆 | **Multiclass de verdade** — tags do `ui_car.json`, paleta com 1 clique, isolamento por categoria |
| 🎙️ | **Painel do narrador** — foco, favoritos, comparação, layouts e resultados na mão |
| 🚩 | **Real Penalty** — selos DT/SG/TIME/WARN/DQ, safety car e alertas direto do chat da sala |
| 🖥️ | **19 janelas redirecionáveis** + layouts salvos (Corrida, Quali, Replay, Vertical) |

## 📦 Instalação

1. Baixe o **[último release](../../releases)** e extraia a pasta `Streamer Hud` para `assettocorsa/apps/lua/`.
2. Ative **Streamer Hud** nos apps Lua do CSP e **reinicie o AC** (o manifest só recarrega ao abrir o jogo).
3. Abra as janelas na barra lateral de apps (`TV Tower`, `TV Battle`, …) e ajuste tudo em **`TV Settings`**.

## 📺 OBS Studio (recomendado)

1. No jogo, abra o app **OBS Apps Redirection** e marque as janelas `TV ...`.
2. No OBS, na fonte do Assetto Corsa, escolha a textura **Extra: Redirected apps (transparent)**.
3. As janelas somem da tela e continuam renderizando para a live. As tags 3D ficam na captura do jogo.

## 🪟 Janelas

| Janela | Mostra |
|---|---|
| TV Tower | Posição, piloto, pneu, volta, Δ posições, intervalo, última volta, paginação |
| TV Battle | Dupla, gap, voltas, média e tendência do intervalo |
| TV Delta | Delta live gigante, previsão e barra ±2s |
| TV Relative | Rivais ±8s do focado, com clique para focar |
| TV Telemetry | Velocidade, RPM, marchas 1–8 e mini pedais |
| TV Inputs | Acelerador, freio e volante suavizados |
| TV Timing | Atual, anterior, melhor, delta live e previsão |
| TV Fuel | Litros, consumo/volta, autonomia e alerta |
| TV Session | Série, relógio/voltas, bandeira e ambiente |
| TV Flags | Bandeira gigante (pisca no amarelo) |
| TV Onboard Top / Bar | Identificação do focado |
| TV Spotter | Carros próximos do focado |
| TV Map | Traçado e posições |
| TV Lineup | Grid antes da largada |
| TV Alert | Melhores voltas, bandeiras e punições |
| TV Narrator | Foco manual, favoritos, comparação, layouts |
| TV Results | Pódio, tabela, melhor volta e recorde da pista |
| TV Settings | Todas as configurações |

## ⚙️ Guia rápido

- **Escala e linhas**: `TV Settings → Escala / Linhas da torre` (padrão 12 linhas, como as torres de referência).
- **Coluna da torre**: `TV_TOWER_MODE` alterna AUTO · GAP · BEST · TYRE.
- **Multiclass**: ative a classe, digite a tag do `ui_car.json` e **clique na cor** (12 cores + seletor nativo). Override por carro/skin no focado.
- **Isolar categoria**: escolha em `TV Settings` ou **clique no rodapé da torre** para alternar.
- **Layouts**: salve posições por perfil (Corrida, Classificação, Replay, Vertical).
- **Logo**: coloque em `Streamer Hud/assets/` e informe `assets/logo.png` (PNG/JPG/DDS/BMP).
- **Real Penalty**: funciona junto sem configurar nada — selos e alertas aparecem sozinhos quando o RP anunciar no chat.

## 🧪 Qualidade

```
python tests/run_audit.py
```

**76 grupos** em LuaJIT (`lupa`): 19 janelas em grids 0–40, escalas, ultrawide, UI scale, redirect, cliques, multiclass, Real Penalty e viewports pequenas — sem o jogo.

## 📜 Versões

| Versão | Destaque |
|---|---|
| 12.3 | Real Penalty via chat (selos, alertas, safety car) |
| 12.2 | Torre estilo CMRT (Int + Last), sem códigos, 12 linhas |
| 12.1 | Pneu por linha + polimento (hover, placeholder, divisores) |
| 12.0 | TV Delta, Relative, Fuel, Session, Flags + recordes + pacotes de série |
| 11.5–11.1 | Categorias, pílulas por classe, paleta um clique, posições únicas, escala estável |
| 11.0–10.2 | Correção do pisca, clique para focar, narrador, comparação manual |

<details>
<summary><b>🔧 Detalhes técnicos</b> (clique para expandir)</summary>

- Callbacks registrados como **global** (padrão CMRT) **e** em `script` (padrão wiki).
- Desenho confinado à janela (clips), condição para o redirect funcionar sem cortes.
- Nenhum callback de desenho redimensiona janelas — tamanhos preparados em `script.update`.
- Posições normalizadas 1..N (o jogo às vezes repete/pula `racePosition`).
- Intervalos medidos por passagem têm prioridade; sem referência, `---`.
- Pneus via `ac.getTyresName`; idade e paradas observadas desde o acompanhamento.
- Gaps nativos (`ac.getGapBetweenCars`, throttle 2 s) + estimativa de fallback.
- Penalidades do RP via `ac.onChatMessage` (só leitura); DT/SG limpam ao cruzar o pitlane.
- Persistência em `ac.storage` com prefixo `ETV_*`; recordes por pista em `ETV_rec_*`.
- Tempo de sessão em milissegundos; alpha sempre 0..1; `ac.getUI().uiScale` para escala.
- Estados zerados ao trocar sessão/pista ou retroceder; áudio liberado ao sair.

</details>

## 🙏 Referências

CMRT Broadcast/Complete · YATTA · WEC/NLS/FSH · LapAlly · ACTV · GT7 tags · F1-25 · helicorsa.
Fontes em `fonts/`, sons em `assets/`.
