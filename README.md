<div align="center">
<img src="docs/race-hero.svg" alt="RACE TV — Broadcast Glass HUD para Assetto Corsa" width="100%">
<br>
<a href="https://github.com/Silxyst/RACE.TV"><img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&duration=2600&pause=900&color=1E90FF&center=true&vCenter=true&width=720&lines=19+janelas+prontas+para+o+OBS;Multiclass+%E2%80%A2+Narrador+%E2%80%A2+Real+Penalty;Sua+transmiss%C3%A3o+com+cara+de+TV." alt="19 janelas prontas para o OBS"></a>

<h3>🏁 RACE TV — Broadcast Glass HUD para Assetto Corsa</h3>

<p><strong>A solução definitiva para transmissões de simulação de corrida.</strong></p>

<p>
<a href="../../releases"><img src="https://img.shields.io/badge/version-12.3.0-e10600?style=for-the-badge&logo=github" alt="Version"></a>
<a href="https://www.assettocorsa.net/"><img src="https://img.shields.io/badge/Assetto%20Corsa-CSP%20Lua-orange?style=for-the-badge&logo=lua" alt="CSP Lua"></a>
<a href="tests/"><img src="https://img.shields.io/badge/tests-76%20passing-00b450?style=for-the-badge&logo=pytest" alt="Tests"></a>
<a href="https://obsproject.com/"><img src="https://img.shields.io/badge/OBS-Studio%20Ready-1c37b4?style=for-the-badge&logo=obs-studio" alt="OBS"></a>
<a href="https://www.racecraft.com.br/"><img src="https://img.shields.io/badge/Real%20Penalty-Compatible-ffd500?style=for-the-badge&logo=warning" alt="Real Penalty"></a>
</p>

<p><strong><a href="https://silxyst.github.io/RACE.TV/">🌐 Visite o Site</a></strong> • <strong><a href="../../releases">📥 Download</a></strong> • <strong><a href="docs/">📖 Documentação</a></strong> • <strong><a href="../../discussions">💬 Discussões</a></strong></p>

<p><a href="#-características-principais">✨ Características</a> • <a href="#-da-largada-ao-pódio">🎬 Transmissão</a> • <a href="#-janelas-disponíveis-19-total">📺 Janelas</a> • <a href="#-instalação-rápida">🚀 Instalação</a> • <a href="#-integração-com-obs-studio">🖥️ OBS</a> • <a href="#-faq">❓ FAQ</a></p>
</div>

## ✨ Características Principais

<table align="center">
<tr>
<td align="center" width="50%">

### 🏆 **Torre de Transmissão**
Posição, piloto, pneu, volta, ΔPos, intervalo, última volta com paginação estável e clique para focar

</td>
<td align="center" width="50%">

### ⚔️ **Battle e Comparação**
Dupla automática ou A/B manual, com última volta, média e tendência

</td>
</tr>
<tr>
<td align="center" width="50%">

### 📊 **Telemetria Dedicada**
Delta, Relative, Timing e Combustível do piloto focado em tempo real

</td>
<td align="center" width="50%">

### 🏅 **Multiclass Real**
Tags do `ui_car.json`, paleta com 1 clique, isolamento por categoria

</td>
</tr>
<tr>
<td align="center" width="50%">

### 🎙️ **Painel do Narrador**
Foco, favoritos, comparação, layouts e resultados ao alcance

</td>
<td align="center" width="50%">

### 🚩 **Real Penalty Integration**
Selos DT/SG/TIME/WARN/DQ, safety car e alertas direto do chat

</td>
</tr>
</table>

<a id="aovivo"></a>
## 🎬 Da largada ao pódio

<img src="docs/race-cycle.svg" alt="Transmissão RACE TV: torre, batalha, delta, resultados" width="100%">

## 📺 Janelas Disponíveis (19 Total)

| Janela | Descrição |
|--------|-----------|
| **TV Tower** | Classificação com posição, piloto, pneu, volta e gap |
| **TV Battle** | Duelo entre dois pilotos |
| **TV Delta** | Delta gigante com previsão |
| **TV Relative** | Rivais próximos (±8s) |
| **TV Telemetry** | Velocidade, RPM, marchas e pedais |
| **TV Inputs** | Entrada de controles suavizada |
| **TV Timing** | Tempos: atual, anterior, melhor |
| **TV Fuel** | Combustível, consumo e autonomia |
| **TV Session** | Série, relógio, bandeira, clima |
| **TV Flags** | Bandeira em grande escala |
| **TV Onboard Top** | Faixa superior de identificação do piloto focado |
| **TV Onboard Bar** | Tarja inferior (lower third) do piloto focado |
| **TV Spotter** | Carros próximos |
| **TV Map** | Traçado e posições ao vivo |
| **TV Lineup** | Grid antes da largada |
| **TV Alert** | Melhores voltas e punições |
| **TV Narrator** | Painel de narração com controles |
| **TV Results** | Pódio, tabela e recorde da pista |
| **TV Settings** | Todas as configurações |

<img src="docs/race-divider.svg" alt="" width="100%">

## 🚀 Instalação Rápida

### 1️⃣ Download

Baixe o **[último release](../../releases)** e extraia a pasta `Streamer Hud` para:

```
assettocorsa/apps/lua/
```

### 2️⃣ Ativação

- Abra Assetto Corsa
- Vá para **CSP Apps → Lua Apps**
- Ative **Streamer Hud**
- **Reinicie o AC**

### 3️⃣ Configuração

- Abra as janelas em **Apps → TV Tower, TV Battle, ...**
- Configure tudo em **TV Settings**
- Escolha o layout desejado

## 🖥️ Integração com OBS Studio

```mermaid
graph LR
    A["🎮 Assetto Corsa"] --> B["OBS Apps Redirection"]
    B --> C["Marcar Janelas TV"]
    C --> D["OBS Source"]
    D --> E["Selecionar Extra: Redirected apps"]
    E --> F["✨ Transmissão Perfeita"]
```

### Passos:

1. No jogo: **OBS Apps Redirection** → marque as janelas `TV ...`
2. No OBS: selecione **Extra: Redirected apps (transparent)**
3. Pronto! As janelas desaparecem da tela mas continuam renderizando

## ⚙️ Guia Rápido de Configuração

| Configuração | Localização | Nota |
|---|---|---|
| **Escala** | `TV Settings → Escala` | Padrão: 12 linhas |
| **Coluna Torre** | `TV_TOWER_MODE` | AUTO / GAP / BEST / TYRE |
| **Multiclass** | `TV Settings` | 12 cores + seletor nativo |
| **Isolar Categoria** | Footer da torre | Um clique para alternar |
| **Layouts** | Salve por perfil | Corrida, Quali, Replay, Vertical |
| **Logo** | `assets/logo.png` | PNG/JPG/DDS/BMP |
| **Real Penalty** | Automático | Funciona sem configurar |

## 🧪 Qualidade e Testes

Executar testes:

```bash
python tests/run_audit.py
```

**76 grupos de testes** em LuaJIT:

- ✅ 19 janelas em grids 0–40
- ✅ Escalas e ultrawide
- ✅ UI scale e redirect
- ✅ Cliques e multiclass
- ✅ Real Penalty
- ✅ Viewports pequenas

## 📊 Histórico de Versões

| Versão | Destaque |
|--------|----------|
| **12.3** | Real Penalty via chat (selos, alertas, safety car) |
| **12.2** | Torre estilo CMRT (Int + Last), sem códigos, 12 linhas |
| **12.1** | Pneu por linha + polimento (hover, placeholder, divisores) |
| **12.0** | Delta, Relative, Fuel, Session, Flags + recordes |
| **11.5–11.1** | Categorias, pílulas por classe, paleta um clique |
| **11.0–10.2** | Pisca corrigido, clique para focar, narrador |

## 🔧 Detalhes Técnicos

<details>
<summary><b>Clique para expandir</b></summary>

- **Callbacks**: Registrados como global (padrão CMRT) e em `script`
- **Desenho**: Confinado à janela (clips) para redirect sem cortes
- **Redimensionamento**: Nenhum callback de desenho redimensiona janelas
- **Posições**: Normalizadas 1..N (jogo às vezes repete/pula `racePosition`)
- **Intervalos**: Medidos por passagem têm prioridade
- **Pneus**: Via `ac.getTyresName` com idade e paradas observadas
- **Gaps**: Nativos (`ac.getGapBetweenCars`) + fallback
- **Real Penalty**: Via `ac.onChatMessage` (leitura)
- **Persistência**: `ac.storage` com prefixo `ETV_*`
- **Tempo**: Em milissegundos, alpha 0..1

</details>

## 🎨 Customização Avançada

### Identidade visual

Tudo se ajusta pela **TV Settings** dentro do jogo — sem editar arquivos:

- **Cores e logo**: aponte o caminho do logo na TV Settings (`assets/logo.png` aceita PNG/JPG/DDS/BMP)
- **Fontes**: arquivos TTF em `Streamer Hud/fonts/` (já inclui Archivo + OpenSans)

### Assets Customizados

- Logo: `Streamer Hud/assets/logo.png`
- Sons: `Streamer Hud/assets/sounds/`

<img src="docs/race-divider.svg" alt="" width="100%">

## ❓ FAQ

<details>
<summary><b>Preciso do OBS para usar o RACE TV?</b></summary>
<br>
Não. As 19 janelas funcionam dentro do jogo. O OBS entra só quando você quer transmitir — via redirect, as janelas somem da tela e seguem renderizando na live.
</details>

<details>
<summary><b>Funciona sem servidor Real Penalty?</b></summary>
<br>
Sim. A integração é automática e só de leitura do chat: sem RP, os selos e alertas apenas não aparecem. Nada precisa ser configurado.
</details>

<details>
<summary><b>Onde configuro tudo?</b></summary>
<br>
Na janela <b>TV Settings</b> dentro do jogo: escala, coluna da torre, multiclass, layouts por perfil, logo e Real Penalty.
</details>

<details>
<summary><b>Como coloco o logo da minha liga?</b></summary>
<br>
Salve o arquivo em <code>Streamer Hud/assets/logo.png</code> (vale PNG, JPG, DDS ou BMP) e aponte o caminho na TV Settings.
</details>

<details>
<summary><b>Como rodo os testes?</b></summary>
<br>
Com <code>python tests/run_audit.py</code> — auditoria de regressão em LuaJIT que valida as 19 janelas sem precisar abrir o jogo.
</details>

## 🙏 Referências e Inspiração

Agradecimentos a:

- **CMRT** (Broadcast/Complete)
- **YATTA** e comunidade
- **WEC/NLS/FSH** pela telemetria
- **LapAlly** e **ACTV**
- **F1 25** pelos estilos
- **helicorsa** pela expertise

## 📞 Suporte e Contribuição

- 💬 [Discussões](../../discussions) - Dúvidas e sugestões
- 🐛 [Issues](../../issues) - Reportar bugs
- 📖 [Wiki](../../wiki) - Documentação técnica
- 🌟 Gostou? Deixe uma estrela ⭐

<div align="center">
<img src="docs/race-divider.svg" alt="" width="100%">

### Feito com ❤️ para a comunidade de simulação de corrida

**[Visite o Site](https://silxyst.github.io/RACE.TV/)** • **[Baixe Agora](../../releases)** · <a href="#aovivo">voltar ao topo ↑</a>
</div>