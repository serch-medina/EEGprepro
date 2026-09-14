% La desventaja de este acercamiento es que si selecciones toda la ventana
% de ensayo, no puedo detectar con mayor exactitud donde se encuentra el
% artefacto. Como le hacemos... 
% - No hace falta, si el ensayo no es optimo, hay que desecharlo.
% Pendiente, indicar tipo de evento y finura. 

% El algoritmo espera un conjunto de datos que han sido agrupados en epocas
% por lo que no funcionara si esto no se cumple.

dpath = fullfile('segmentado/');

[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 
% Prueba con el set de datos epoqueado de Mer
EEG = pop_loadset('H01COM_ppepoch1a2.set',dpath);
eeglab redraw

fs = EEG.srate;

% --- PARÁMETROS DE CONFIGURACIÓN CONFIGURABLES ---

% Umbral de canales simultáneos para etiquetar un evento como ruidoso.
min_channels_noisy = 8;

% -- Parametros estadisticos (z-score) --
z_MAFD_f = 3; % f: factor
k = 10;
z_MAkD_f = 3; % Max. k-th diff.
z_freq_f = 3; 
% == Parametros estadisticos (Algoritmo de Tamburro) ==
amp_MAFC = 4.5; % a: amplitud
amp_HRFC = 1.5;
% -- Parametros fisiologicos --
MAA_thresh_volt = 75;
min_MAA_tresh = 60;
max_MAA_tresh  = 75;
% == Parametros de frecuencia y calculo de potencia ==
min_freq = 5;
max_freq = 50;
nfft = 256;
welch_window_number = 10;
% Parametros de muestreo paralelo y alterno de potencia usando Welch                                       
window_size = length(EEG.data(1,:,1)); % En muestras, 750 puntos.
welch_window = hamming(round(window_size/welch_window_number)); % Largo de ventana para calculo de potencia. 
noverlap = floor(length(welch_window)/2);

% == Validacion ==
% Checa que k no sea mayor a floor(#muestras/2), sino se desperdicia mucha
% info.
if k > floor(length(EEG.data(1,:,1)) / 2)
    error("Entero demasiado grande para realizar diferencias. " + ...
        "Se desperdiciaran muchas muestras. " + ...
        "Pruebe con uno menor a la mitad de la logitud de sus ensayos")
end

% --- INICIALIZACIÓN ---
[num_channels, num_points, num_of_epochs] = size(EEG.data);
fs = EEG.srate; % Frecuencia de muestreo (250 Hz)
noise_matrix = false(num_channels, num_of_epochs); % Va a ser de 32 x 198 o 160. Cada ventana es la duracion de un ensayo.

fprintf('Iniciando detección de ruido mediante algoritmo de Tamburro et al. en %d canales y en %d ensayos \n', num_channels, num_of_epochs); 

% Primero definirlo una vez e ir guardando... problema, en tal caso,
% podriamos tomar datos que no corresponden, mejor volver a ceros cada itereacion. 

% == Reservacion de memoria ==
% Activamos la bandera de deteccion de ruido en la siguiente iteracion
% vera si esta en true o false.
prev_selected = false(1,num_of_epochs); % Solo activar con Tamburro-condiciones (!)
MAA = zeros(1,num_of_epochs);
MAFD = zeros(1,num_of_epochs);
HRFC = zeros(1,num_of_epochs);
% --- 1. BUCLE para seleccion con algoritmo de ruido ---
for ch = 1:num_channels
    % -- Reinicio de valores --
    prev_selected(:) = false;
    MAA(:) = 0;
    MAFD(:) = 0;
    HRFC(:) = 0;

    for w = 1:num_of_epochs % w de window
        signal = double(EEG.data(ch, : , w)); % formato double para precisión (nvl. de precision de los datos grabados, por defecto)
                                              % la ventana es el numero de
                                              % ensayo o epoch
        MAA_w_c = max(abs(signal)); 
        MAA(w) = MAA_w_c;
        MAFD(w) = max(abs(diff(signal))); % Calculo y guardado de la MAFD_w_c
        [Pxx, f] = pwelch(signal, welch_window, noverlap, nfft, fs); 

        % Potencia por encima de 50 Hz. 
        % Calculamos potencia de frecuencia rapida.
        P_high = bandpower(Pxx, f, [50 fs/2], "psd"); % Teorema de Nyquist, NO se puede reconocer una frecuencia mayor a la mitad de la de muestreo en una grabacion discreta.
        % Potencia total
        P_total = bandpower(Pxx, f, [0 fs/2], "psd");
        HRFC(w) = P_high / P_total; % Calculamos la HRFC_c_w
    end

    % ======== Condiciones de z-score ========

    % Calculamos MAD de MAFD_c
    % El factor 0.6745 escala MAD para equivaler a desviación estándar.
    sigma_fd = custom_mad(MAFD); % Nos dice donde se parte en dos el conjunto de distancias respecto a la mediana
    threshold = median(MAFD) + (z_MAFD_f * sigma_fd);
    % Calculamos MAD de RFC_c
    sigma_f = custom_mad(HRFC); % Nos dice donde se parte en dos el conjunto de distancias respecto a la mediana
    threshold_f = median(HRFC) + (z_freq_f * sigma_f);

    % ========== Condiciones z-score ===================
    C1 = MAFD > threshold; % hace comparacion elemento a elemento 
    C2 = HRFC > threshold_f;

    % ========== Condiciones Predefinidas ==============
    C3 = MAA > MAA_thresh_volt;
    C4 = MAFD > amp_MAFC*(median(MAFD) + sigma_fd);
    C5 = (min_MAA_tresh < MAA) & (MAA < max_MAA_tresh) & (HRFC > amp_HRFC*(median(HRFC) + sigma_f));
    prev_selected = C3 | C4 | C5; % Guardamos los eventos ya detectados para la
    % -- Condicion basada en bandera --
    condicion = noise_matrix(ch,:) == true;
    condicion = condicion(1:end-1); % quitamos ultimo valor
    prev_selected(condicion) = true; 
    % recorremos la bandera
    b_futuro = [prev_selected(2:end), false]; % en el utlimo elem no tiene sentido evaluar, ponemos false.
    b_pasado = [false,prev_selected(1:end-1)]; % en el primer elem "", ponemos false.
    C6 = (min_MAA_tresh < MAA) & (MAA < max_MAA_tresh) & (b_pasado == true | b_futuro == true);

    noise_matrix(ch, :) = C1 | C2 | C3 | C4 | C5 | C6; 
end

% --- 2. CONDICIÓN DE COINCIDENCIA MULTICANAL ---
channels_detecting_noise = sum(noise_matrix, 1);

% Encontrar los puntos de tiempo que cumplen con el número mínimo de canales ruidosos
noisy_events = find(channels_detecting_noise >= min_channels_noisy);