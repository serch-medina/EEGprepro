% Se requiere de la Wavelet Toolbox de Matlab Instalada
dpath = fullfile('segmentado/');

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 
% Prueba con el set de datos epoqueado de Mer
EEG = pop_loadset('H01COM_ppepoch1a2.set',dpath);
eeglab redraw

% --- PARÁMETROS DE CONFIGURACIÓN CONFIGURABLES ---
% Tecnicamente Freq maxima
min_freq = 5;                  % Frecuencia mínima para buscar ruido (en Hz)
                                % Frecuencia alta nos ayuda a detectar
                                % ruido, sin marcar actividad natural.
max_freq = 50;
threshold_factor = 3;           % Multiplicador del umbral (la desviacion MAD)
min_channels_noisy = 1;         % NÚMERO MÍNIMO DE CANALES simultáneos para etiquetar evento

% --- INICIALIZACIÓN ---
[num_channels, num_points] = size(EEG.data);
fs = EEG.srate;                 % Frecuencia de muestreo (250 Hz)
noise_matrix = false(num_channels, num_points); % nos aloja espacio en memoria
                                                % (inicializa valores en
                                                % cero) para marcar ruido
                                                % Es una matriz.

% Para saber en que canal esta: Tomar la posicion del evento, dividirla
% entre 750 con division entera, luego agarrar la posicion relativa
% guardada en el evento. 

fprintf('Iniciando detección de ruido mediante CWT en %d canales...\n', num_channels);

% --- 1. BUCLE MULTICANAL CON CWT ---
for ch = 1:num_channels
    
    % Tal vez hacer un doble bucle uno para frecuencias bajas y otro para
    % altas. Por ejemplo el ruido de musculos puede estar en el espectro de
    % +30 Hz. Habria que cambiar el TimeBandwidth en cada caso

    signal = double(EEG.data(ch, :)); % Asegurar formato double para precisión
                                      % Al solo seleccionar dos
                                      % dimensiones, se colapsa la tercera,
                                      % esto es, se concatenan los datos de
                                      % diferentes ensayos.

    % Calcular CWT (Matriz de Tiempo-Frecuencia)
    [wt, f] = cwt(signal, fs, TimeBandwidth=20); % personalizamos un valor bajo de Time-Bandwidth, para que reconozca transitorio electricos y musculares y de 'electrode pop'
    % El wt, usa indices: wt(i: frecuencia, j: tiempo)
    % (?) ¿la frecuencia va del mas alto al mas bajo o al reves? 

    % Filtrar solo las frecuencias altas donde se concentra el ruido/artefacto
    high_freq_mask = (f >= max_freq); % mascara logica

    if ~any(high_freq_mask)
        error('La frecuencia mínima configurada supera el límite de Nyquist de tu señal.');
    end

    % Obtener el módulo (valor absoluto) de los coeficientes en el rango de interés
    wt_magnitude = abs(wt(high_freq_mask, :)); % recupera todas las filas y obtiene su modulo. Devuelve una MATRIZ (!)

    % Crear un perfil de energía promediando las frecuencias seleccionadas para cada punto de tiempo
    % Al usar CWT, este vector ya tiene exactamente la misma longitud (num_points) que la señal original
    % A diferencia de al usar DWT
    energy_profile = mean(wt_magnitude, 1); % Hace promedio con los elem. de COLUMNAS

    % Calcular el umbral robusto usando la Desviación Absoluta de la Mediana (MAD)
    % El factor 0.6745 escala la MAD para que equivalga a una desviación estándar en distribuciones normales
    sigma = median(abs(energy_profile - median(energy_profile))) / 0.6745; % Nos dice donde se parte en dos el conjunto de distancias respecto a la mediana
    threshold = median(energy_profile) + (threshold_factor * sigma);

    % Marcar en la matriz binaria los puntos temporales que superan el umbral en este canal
    noise_matrix(ch, :) = energy_profile > threshold; % hace comparacion elemento a elemento 
end

% --- 2. CONDICIÓN DE COINCIDENCIA MULTICANAL ---
% Sumar cuántos canales detectan ruido de forma síncrona en cada muestra
channels_detecting_noise = sum(noise_matrix, 1);

% Encontrar los puntos de tiempo que cumplen con el número mínimo de canales ruidosos
noisy_indices = find(channels_detecting_noise >= min_channels_noisy); % crea una mascara logica, luego evalua donde indica 
                                                                      % que si hay ruido y recupera sus indices

% --- 3. CREACIÓN Y ETIQUETADO DE EVENTOS EN EEGLAB ---
if ~isempty(noisy_indices)
    % Agrupar puntos consecutivos para consolidar bloques de ruido continuos
    diff_indices = diff(noisy_indices); % lit saca las diferencias entre
                                        % elementos consecutivos. Como es
                                        % un vector de indices, nos dice si
                                        % hay muestras ruidosas consecutivas.
                                        % La sintaxis vec([ind]), nos
                                        % regresa un subvector con los elem
                                        % en los indices indicados por ind

    event_starts = noisy_indices([1, find(diff_indices > 1) + 1]); % Inicio de eventos. Sumamos 1 por que se recorrio el arreglo cuando hicimos diff
    event_ends = noisy_indices([find(diff_indices > 1), end]); % Fin de eventos

    % Inicializar array de estructuras para los nuevos eventos
    new_events = [];

    for e = 1:length(event_starts)
        % Define un struct de evento con varios campos como tipo, latencia
        % y duracion. Para combinarlos con los de EEGLAB
        new_event = struct();
        new_event.type = 'Artifact_CWT';
        new_event.latency = event_starts(e); % Posición en muestras
        new_event.duration = event_ends(e) - event_starts(e) + 1; % Duración en muestras

        % Campos requeridos por EEGLAB por compatibilidad
        new_event.urevent = []; 

        new_events = [new_events, new_event];
    end

    % Aun no hare este paso de insertarlo aunque podria ser util, pero no
    % se ya que tengo que tenerlos bien etiquetados
    % Esto es lo que da error, y sucede ya que los struct en EEGLAB tienen
    % mas campos y no se puede agregar al array de eventos, eventos
    % definidos con menos campos.

    % % Combinar con los eventos preexistentes si los hay
    % if isempty(EEG.event)
    %     EEG.event = new_events;
    % else
    %     EEG.event = [EEG.event, new_events]; % Concatenacion de arrays. Marca error dice que numero de campos no coincide
    % end

    % Validar y ordenar cronológicamente la estructura de eventos dentro de EEGLAB
    EEG = eeg_checkset(EEG, 'eventconsistency');
    fprintf('¡Éxito! Se añadieron %d eventos de ruido (''Artifact_CWT'') a la señal.\n', length(event_starts));
else
    fprintf('Análisis completado. Ningún evento alcanzó el mínimo de %d canales con ruido simultáneo.\n', min_channels_noisy);
end

% =============== Graficar ===============
% Debo recuperar la actividad de un canal, pero no toda solo en una ventana
% de tiempo, observar si efectivamente hay ruido o no

canal = 32;                    % Canal a visualizar
padding = round(5*fs);       % 500 ms

ini = max(1,event_starts(4)-padding);
fin = min(num_points,event_ends(4)+padding);

senal = EEG.data(canal,ini:fin);
t = (ini:fin)/fs;
vent_energia = energy_profile(ini:fin);

% Renormalizamos
vent_energia = vent_energia/max(vent_energia);
vent_energia = vent_energia*max(abs(senal));

figure
plot(t,senal,'k')
xlabel('Tiempo (s)')
ylabel('Amplitud (\muV)')
title(sprintf('Canal %d',canal))
grid on
hold on
plot(t,vent_energia,'r','LineWidth',2)
legend('EEG','Magnitud CWT')
zoom on

% Observar un mapa de calor de la matriz de frecuencias (pero es el del
% ultimo canal! Porque la wt se define en cada iteracion XDDD)
figure
imagesc(t,f,abs(wt(:,ini:fin)))
axis xy
xlabel('Tiempo')
ylabel('Frecuencia')
colorbar
zoom on

% RECORDAAR! esta epoqueado por 750 muestras. Entonces con el numero
% epoca (69), podemos estimar donde debe estar en latencia