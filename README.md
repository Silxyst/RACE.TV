# RACE TV 12.3 — Broadcast Glass

Redesign total da interface: cartões em glass escuro com filete de acento,
pílulas arredondadas, tipografia condensada e animações de entrada (fade +
deslize) nos painéis, com temas aplicados ao fundo e aos destaques.

## Compatível com Real Penalty (12.3)

- O HUD lê os avisos do RP no chat da sala (`ac.onChatMessage`, só leitura,
  nunca consome mensagens): drive-through, stop-go (com segundos), punição de
  tempo, avisos de corte e desclassificação.
- Selo de punição na coluna de volta da torre (DT, SG10, +20, W2, DQ);
  DT/STOP-GO somem sozinhos ao cumprir no pitlane; avisos valem a sessão.
- Safety car / VSC / bandeira verde do RP entram na TV Flags, na faixa de
  ambiente e nos alertas com som.
- Sem RP na sala, nada muda: o módulo fica silencioso. Sem conflito de arquivos,
  storage, janelas ou áudio com o app do RP.

## Torre estilo CMRT, sem códigos, 12 linhas (12.2)

- Linhas no arranjo Pos | Piloto | Pneu | Volta | ΔPos | Int | Last, no visual
  Broadcast Glass de sempre; códigos MC1/MC2/GT3 fora das linhas (classe segue
  na pílula de posição, no tooltip e no isolamento).
- Seta com número de posições ganhas/perdidas (▲1, ▼10).
- Torre mais larga (400) e padrão de 12 linhas como as torres de referência.

## Pneu por linha + polimento geral (12.1)

- Torre mostra o pneu de cada piloto (ponto colorido + letra) em MC1/MC2 e nas
  demais classes, em todos os modos; interruptor em `TV Settings`.
- Battle com classe + pneu na linha de comparação; onboard com código da classe.
- Hover com destaque na linha, divisor sobre o rodapé e `AGUARDANDO CARROS`
  em vez de janela vazia no grid vazio.

## Cinco janelas novas + pacotes de série + recordes (12.0)

- **TV Delta**: live gigante, previsão e barra ±2s do focado.
- **TV Relative**: rivais ±8s do focado (nativo + estimado), com clique para focar.
- **TV Fuel**: litros, consumo/volta, autonomia e alerta de pouco combustível.
- **TV Session**: série, relógio/voltas, bandeira, ambiente e progresso.
- **TV Flags**: bandeira gigante (pisca no amarelo) para o broadcast.
- **Pacotes de série**: WEC Azul, IMSA Vermelho e F1 Vermelho aplicam cor + título juntos.
- **Recorde da pista**: melhor volta all-time por traçado, persistente, no rodapé dos resultados.
- Blindagem: todo acesso a API nova com `pcall`/throttle, `SEM DADOS` em vez de janela vazia,
  sem resize em desenho e sem escrita contínua no storage.

## Categorias visíveis e isoláveis na torre (11.5)

- Código da categoria em cada linha (GT3, GT4, MC1...) ao lado do nome.
- Isolamento: Automática (focado), Todas ou uma categoria — em `TV Settings`
  ou com um clique no rodapé da torre (alterna sem abrir ajustes).
- Categoria inexistente volta a mostrar tudo, sem torre vazia.

## Multiclass na torre: pílula de posição por classe (11.4)

- Posição em pílula na cor da classe (texto claro/escuro por luminância);
  líder/focado mantêm destaque branco com número em pílula escura.
- Tooltip da linha mostra a classe (`MC1 ALPHA`, `GT3`...) + gap ao líder.

## Multiclass com cores em um clique (11.3)

- Adeus `#RRGGBB` digitado: paleta broadcast de 12 cores com um clique por classe,
  seletor nativo do CSP para cor livre e prévia da cor atual.
- Dica automática: mostra quais carros do grid casam com a tag digitada.
- Cores antigas salvas continuam valendo; override por skin inalterado.

## Tower nunca corta nem esvazia com janela limitada (11.2.1)

- Quando o CSP limita a altura da janela, a torre pagina no que realmente cabe
  em vez de desenhar linhas cortadas; o tamanho cheio segue sendo solicitado,
  então a janela volta a crescer em qualquer mudança de escala/linhas.
- Trava anti-vazio: com carros na pista, a torre sempre mostra linhas.

## Novidades YATTA + correção da logo (11.2)

- Logo: aceita PNG/JPG/JPEG/DDS/BMP, procura na pasta do app e em `assets/`,
  mostra o caminho quando não encontra e reserva o espaço enquanto a textura carrega.
  Dica: coloque o arquivo em `Streamer Hud/assets/` e informe `assets/logo.png`.
- Gap nativo ao líder (`ac.getGapBetweenCars`, atualizado a cada 2 s) na Battle,
  no narrador e no tooltip da torre. Número real do carro (`ac.getDriverNumber`)
  como padrão; override manual continua vencendo.
- Faixa de ambiente na torre (toggle): pílula de bandeira (YELLOW/GREEN/CHEQUERED/LAP)
  + grip, temperaturas da pista/ar e hora local. Altura incluída no orçamento da janela.
- Multiclass por tags do `ui_car.json` (6 slots com cor) + override por skin; heurística
  anterior vira fallback. Cache invalidado ao trocar regras ou sessão.

## Auditoria da Tower: interface, design e escala (11.1.1)

- Altura segue o conteúdo real: sem vão vazio quando há menos carros que o ajuste de linhas.
- Linhas com altura mínima legível (22–30): a pílula da marca e as fontes não são espremidas;
  viewport pequena pagina em vez de encolher.
- Setas ▲▼ por identidade do piloto: troca de piloto no mesmo índice não gera seta falsa,
  e índices removidos são limpos.
- Logs reais sem erro da Tower; apenas realocações iniciais de glifos e um pico isolado de 31 ms
  no Onboard Top. Geometria validada sem overflow em grids, escalas, resoluções e UI scales.

## Posições únicas e Tower com foco total (11.1)

- O jogo pode reportar `racePosition` duplicado ou pulado (P2 2x, sem P13).
  A classificação agora normaliza para uma sequência única 1..N na ordem real.
  Pódio usa P1/P2/P3 pela ordem e a tabela usa a posição geral, sem repetir.
- Tower 100% focada: posição por rank único, líder + focado sempre visíveis,
  linha inteira clicável para acompanhar o piloto e moldura na cor do tema
  destacando o focado.

## Correção de escala e pisca + novas funções (11.0)

- Uma **escala comum** para todo o HUD (`TV Settings → Escala`): a torre com
  20 carros mantém a mesma largura e o mesmo tamanho de fonte dos outros
  widgets em 1080p. Ela pagina o conteúdo em vez de encolher.
- Nenhum callback de desenho redimensiona janelas. Todos os tamanhos são
  preparados uma vez em `script.update`; solicitações lógicas repetidas não
  reenviam resize, o que elimina o pisca ao trocar escala/linhas.
- Fontes ajustadas em passos de meio ponto, evitando realocação contínua do
  atlas de glifos (causa dos travamentos longos registrados no log real).
- Clique no nome da torre continua valendo na janela visível do jogo, com
  foco por índice real, proteção contra duplicação do OBS e pilotos
  desconectados ignorados.

## Painel do narrador e comparação manual

- Nova janela **`TV Narrator`**: botões LÍDER, ANTERIOR, PRÓXIMO, favoritar,
  próximo favorito, ATUAL → A/B, limpar dupla, abrir resultados e trocar layout.
- Favoritos persistidos por identidade (nome + modelo), sem reaproveitar
  índice trocado ou desconectado.
- Atalhos configuráveis em `TV Settings`: focar líder/anterior/próximo,
  favoritar, próximo favorito, comparação A/B e próximo layout.
- `TV Battle` mostra a dupla manual com última volta, média das últimas 3 e
  tendência do intervalo (aproximando/afastando/estável).

## Intervalos por pontos de passagem

- 80 referências por volta com timestamps interpolados. O intervalo medido tem
  prioridade sobre a estimativa por distância/velocidade.
- Box, pista, teleporte, rewind e troca de piloto invalidam as observações;
  sem valores fabricados (`---` quando não há referência válida).
- Histórico limitado a 5 voltas/400 pontos para não pesar em grids grandes.

## Tela de resultados

- Nova janela **`TV Results`**: pódio (P1–P3), tabela paginada, melhor volta
  geral, status FINISHED/DNF/DISCONNECTED e estado PROVISÓRIO/FINAL.
- Snapshots por identidade: desconexão ou troca de nome após a bandeirada não
  apaga o pódio nem a melhor volta.

## Layouts salvos

- Perfis **Corrida, Classificação, Replay e Vertical** em `TV Settings`.
- Cada perfil guarda escala, linhas da torre, posições normalizadas e janelas
  visíveis. Aplicação e salvamento acontecem em `script.update`, sem mexer na
  camada de redirecionamento do CSP.
- Perfis corrompidos voltam ao padrão; `TV_LAYOUT_NEXT` e o painel do narrador
  trocam de perfil. O modo Vertical organiza uma coluna para recorte no OBS.

## Identidade visual personalizada

- Cor personalizada RGB, logo PNG/JPG/DDS (relativo ou absoluto) exibido na
  torre, onboard, lineup e resultados, além de número e equipe por piloto.
- Metadados por identidade do piloto; caminho inválido mostra aviso sem
  quebrar o desenho.

## Torre com 10–20 pilotos e clique para focar (10.2)

- O tamanho da torre é preparado em `script.update`, antes de iniciar o desenho.
  O callback de renderização não redimensiona a janela em nenhuma passagem.
- Clique com o botão esquerdo no **nome do piloto na TV Tower do jogo** para
  acompanhá-lo. A área clicável acompanha a posição animada da linha e a escala.
- A textura no OBS não recebe cliques de volta ao jogo. Para selecionar pilotos
  quando usa redirecionamento, mantenha uma cópia visível da torre no AC.

## Correções de estabilidade e cores (10.1)

- A torre mantém o número de linhas e a altura na última página, usando uma
  faixa final sobreposta em vez de reduzir o tamanho da janela.
- A posição animada das linhas é atualizada na lógica por frame. Desenhar
  novamente para o OBS não avança a animação nem muda as posições.
- Notificações repetidas de abertura/redimensionamento não reiniciam a entrada.
- Em **TV Settings → Tema de cores do HUD**, Race Red / Enduro Blue / NLS Green
  mudam os fundos e destaques imediatamente. A seleção ativa é exibida em texto.
- Ao trocar de piloto, as leituras suavizadas de inputs/delta são reiniciadas.
  Delta remoto indisponível não é apresentado como uma volta válida.

- Tower: cabeçalho com série + sessão/clock, barra de progresso, linhas com
  pílula de posição, setas ▲▼, marca, nome com clip e coluna GAP/BEST/TYRE.
- Battle: cards com faixa do piloto, gap em destaque, melhor volta e S1S2S3 ao vivo.
- Telemetry: pop ao trocar de marcha, shift flash, mini barras THR/BRK.
- Inputs: barras suavizadas + graus arredondados.
- Timing: delta live suavizado + previsão + barra móvel ±2s + mini setores.
- Onboard Bar/Top, Spotter, Map, Lineup e Alert na mesma linguagem visual.
- Todo desenho é recortado dentro da janela para o redirecionamento ao OBS.

## Janelas redirecionáveis ao OBS

Cada elemento do HUD é uma **janela real de app** que desenha o próprio
conteúdo. Isso permite usar o app **OBS Apps Redirection** do CSP e expor as
janelas na textura **Extra: Redirected apps (transparent)** do plugin do OBS.

## Carregar e configurar

1. Feche o Assetto Corsa e abra novamente para carregar o manifest atual.
2. Deixe `Streamer Hud` habilitado entre os apps Lua do CSP.
3. Abra as janelas desejadas na barra lateral de apps (`TV Tower`, `TV Battle`,
   `TV Telemetry`, `TV Narrator`, `TV Results`, etc.) e a janela `TV Settings`.
4. Cada janela ajusta o próprio tamanho ao conteúdo (escala/linhas); com
   **Posicionamento automático** ligado, elas também se reposicionam sozinhas.
5. O atalho `TV_TOWER_MODE` (associável em `TV Settings`) alterna a coluna da
   torre entre AUTO, GAP, BEST e TYRE.

## OBS Studio via Apps Redirection (recomendado)

1. No jogo, abra o app **OBS Apps Redirection** (categoria de configurações).
2. Marque as janelas `TV ...` que devem ir para a transmissão.
3. No OBS, na fonte do Assetto Corsa, escolha a textura
   **Extra: Redirected apps (transparent)**.
4. As janelas redirecionadas somem da tela principal e continuam renderizando
   para o OBS, porque o desenho nunca depende da visibilidade da janela.

As tags 3D dos carros (com pedais progressivos) continuam na captura do jogo;
elas são ancoradas no mundo 3D e não passam pelo Redirection.

## Janelas

| Janela | Informações |
|---|---|
| TV Tower | Posição, piloto, pneu, volta, Δ posições, intervalo, última volta e paginação |
| TV Battle | Dupla manual ou automática, voltas, média e tendência do intervalo |
| TV Onboard Top | Identificação do piloto focado (topo) |
| TV Onboard Bar | Identificação do piloto focado (faixa inferior) |
| TV Telemetry | Velocidade, RPM, marchas 1–8 e pedais reais |
| TV Inputs | Acelerador, freio e volante do carro focado |
| TV Timing | Volta atual, anterior, melhor, delta live e previsão |
| TV Spotter | Carros próximos do piloto focado |
| TV Map | Traçado e posições dos carros |
| TV Lineup | Grid paginado durante a preparação da corrida |
| TV Alert | Fila de melhores voltas e bandeiras, com entrada/saída animada |
| TV Narrator | Foco manual, favoritos, comparação e layouts |
| TV Results | Pódio, tabela final/provisória, melhor volta e recorde da pista |
| TV Delta | Delta live gigante, previsão e barra ±2s |
| TV Relative | Rivais ±8s do focado, com clique para focar |
| TV Fuel | Litros, consumo, autonomia e alerta |
| TV Session | Relógio, voltas, bandeira e ambiente |
| TV Flags | Bandeira gigante para o broadcast |
| TV Settings | Todas as configurações |

## Revisão de bugs

- Callbacks de desenho/abertura/fechamento registrados como **global** (padrão
  CMRT) **e** em `script` (padrão wiki), cobrindo qualquer resolução do CSP.
- Desenho confinado à caixa de cada janela (clips externos nas animações de
  slide/reveal), condição para o redirect funcionar sem cortes.
- Widgets sem carro para mostrar retornam antes de qualquer desenho (pedals,
  radar, map); sem cabeçalhos órfãos vazando para fora da janela.
- Tower mostra `P1` por posição real, scroll por páginas com líder e focado
  fixos, intervalos contra o concorrente real (não o vizinho de página).
- Classificação de treino/quali ordenada por melhor volta; empate estável.
- Tempo de sessão tratado em milissegundos; transparências entre 0 e 1.
- Textos medidos, ajustados e recortados dentro da coluna; acentos truncados
  em caracteres completos.
- Pneus via `ac.getTyresName` (API real); virtual KM detecta troca de jogo do
  mesmo composto quando disponível.
- Paradas contam visitas ao box (saída após ≥1s), sem contar spawn nem
  drive-through.
- Estados reiniciados ao trocar sessão/pista ou retroceder a reprodução.
- Áudio mantido durante a reprodução e liberado ao encerrar o app.
- Mapa considera o layout da pista e não reamostra pista indisponível a cada frame.
- Grid some quando a sessão começa.

## Dados e limites

- Intervalos medidos por passagem têm prioridade; sem referência, a estimativa
  é usada apenas com carro em movimento. Sem referência válida, `---`.
- Idade do pneu e paradas são observadas desde que o app acompanha a sessão.
- Categorias GT3/GT4/LMP2/Hypercar/Formula/Touring por ID/nome; resto em OPEN.
- Pedais remotos/replay dependem da telemetria do jogo; sem valores inventados.
- Delta nativo e previsão exigem volta de referência; senão, `---`.

## Verificação

```
python tests/run_audit.py
```

76 grupos em LuaJIT 2.1 (`lupa`), com campos extraídos do SDK instalado:
19 janelas renderizando em grids 0/1/6/20/40, escalas 0,7/1/1,6, resoluções até
ultrawide, UI scale 1/1,5, registro duplo de callbacks, janelas ocultas ainda
renderizando (redirect), auto-resize e auto-layout. Inclui página final estável,
múltiplos desenhos no mesmo frame, mudança de tema pela UI e telemetria do
piloto focado. Também testa 10/11/12/15/20 linhas com resize atrasado e janela
limitada, ausência de resize no desenho, clique após a nona linha e em páginas
posteriores, escala comum com 20 carros, grade de meio ponto nas fontes,
narrador/favoritos/comparação manual, intervalos por passagem, resultados,
layouts salvos/corrompidos, branding e viewports pequenas.

Execução e lógica são verificadas sem o jogo; a aparência final e a textura
`Extra: Redirected apps` devem ser conferidas no AC + OBS.

Referências: CMRT Broadcast/Complete, WEC/NLS/FSHTV, LapAlly, ACTV, GT7 tags.
Fontes e sons em `fonts/` e `assets/`.
