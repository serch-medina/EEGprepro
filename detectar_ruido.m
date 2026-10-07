% No hace falta indicar exactamente donde se detecto ruido, basta con
% indicar la epoca, la idea es que toda sera desechada si el ruido aparece
% en muchos canales. A menos que se pueda pasar por alto el ruido siempre y
% cuando sea fuera de los eventos mas relevantes (entre el 4 y el 5 me
% parece)... puede ser, pero el ensayo (epoca) que indico Mer que se debia
% eliminar tenia ruido por fuera de esos eventos.

% El algoritmo espera un conjunto de datos que han sido agrupados en epocas
% por lo que no funcionara si esto no se cumple.
% Se espera ademas que eeglab ya este cargado
function [ALLEEG, EEG, CURRENTSET, noisy_epochs] = ...
detectar_ruido(ALLEEG,EEG,CURRENTSET,params)

arguments
    ALLEEG;
    EEG;
    CURRENTSET;
    % -- Parametros estadisticos (z-score) --
    params.channel_number_tresh (1,1) double = 0;
    params.z_MAFD_f (1,1) double = 3; % f: factor
    params.k (1,1) double = 22;  % Max. k-th diff.
    params.z_MAkD_f (1,1) double = 3;
    params.z_freq_f (1,1) double = 3; 
    % == Parametros estadisticos (Algoritmo de Tamburro) ==
    params.amp_MAFC (1,1) double = 4.5; % a: amplitud
    params.amp_HRFC (1,1) double = 1.5;
    % -- Parametros fisiologicos --
    params.MAA_thresh_volt (1,1) double = 75;
    params.min_MAA_tresh (1,1) double = 60;
    params.max_MAA_tresh  (1,1) double = 75;
    % == Parametros de frecuencia y calculo de potencia ==
    params.min_freq (1,1) double = 5;
    params.max_freq (1,1) double = 50;
    params.nfft (1,1) double = 256;
    params.welch_window_number (1,1) double = 10;
end

%  PENDIENTE !: Implementar deteccion por cada k muestras. Creo que ya
%  PENDIENTE !: Implementar argumentos tipo **kwargs. Creo que ya x2

% --- INICIALIZACIÓN (parametros de tamanho)---
[num_channels, num_points, num_of_epochs] = size(EEG.data);
fs = EEG.srate; % Frecuencia de muestreo (250 Hz)
disp(num_points)

% --- PARÁMETROS DE CONFIGURACIÓN CONFIGURABLES (CONFIGURACIONABLES) ---
% Umbral de canales simultáneos para etiquetar un evento como ruidoso.
if (params.channel_number_tresh == 0)
    channel_number_tresh = floor(EEG.nbchan / 2) - 1; % Valor por defecto.
else
    channel_number_tresh = params.channel_number_tresh;
end

% -- Parametros estadisticos (z-score) --
z_MAFD_f = params.z_MAFD_f; 
k = params.k;
z_MAkD_f = params.z_MAkD_f; 
z_freq_f = params.z_freq_f; 
% == Parametros estadisticos (Algoritmo de Tamburro) ==
amp_MAFC = params.amp_MAFC; 
amp_HRFC = params.amp_HRFC;
% -- Parametros fisiologicos --
MAA_thresh_volt = params.MAA_thresh_volt;
min_MAA_tresh = params.min_MAA_tresh;
max_MAA_tresh  = params.max_MAA_tresh;
% == Parametros de frecuencia y calculo de potencia ==
min_freq = params.min_freq;
max_freq = params.max_freq;
nfft = params.nfft;
welch_window_number = params.welch_window_number;

% Parametros de muestreo paralelo y alterno de potencia usando Welch                                       
window_size = length(EEG.data(1,:,1)); % En muestras, 750 puntos.
welch_window = hamming(round(window_size/welch_window_number)); % Largo de ventana para calculo de potencia. 
noverlap = floor(length(welch_window)/2);

% == Validacion ==
% Checa que el umbral de numero de canales no sea negativo ni mayor que el
% numero total de los mismos
if channel_number_tresh < 0
    error("El numero minimo de canales para detectar ruido que ha " + ...
    "ingresado es negativo")
elseif channel_number_tresh > EEG.nbchan
    error("El numero minimo de canales para detectar ruido que ha " + ...
    "ingresado excede el total de canales de la grabacion")
end    

% Checa que k no sea mayor a floor(#muestras/2), sino se desperdicia mucha
% info.
if k > floor(num_points / 2)
    error("Entero demasiado grande para realizar diferencias. " + ...
        "Se desperdiciaran muchas muestras. " + ...
        "Pruebe con uno menor a la mitad de la logitud de sus ensayos")
end

noise_matrix = false(num_channels, num_of_epochs); % Va a ser de 32 x 198 o 160. Cada ventana es la duracion de un ensayo.

fprintf('Iniciando detección de ruido mediante algoritmo de Tamburro et al. (modificado) en %d canales y en %d ensayos \n', num_channels, num_of_epochs); 

% Primero definirlo una vez e ir guardando... problema, en tal caso,
% podriamos tomar datos que no corresponden, mejor volver a ceros cada itereacion. 

% == Reservacion de memoria ==
% Activamos la bandera de deteccion de ruido en la siguiente iteracion
% vera si esta en true o false.
prev_selected = false(1,num_of_epochs); % Solo activar con Tamburro-condiciones (!)
MAA = zeros(1,num_of_epochs);
MAFD = zeros(1,num_of_epochs);
MAkD = zeros(1,num_of_epochs);
HRFC = zeros(1,num_of_epochs);
% Se espera que el numero de muestras en cada epoca sea constante
indices = 1 : k : num_points-k;

% --- 1. BUCLE para seleccion con algoritmo de ruido ---
for ch = 1:num_channels
    % -- Reinicio de valores --
    prev_selected(:) = false;
    MAA(:) = 0;
    MAFD(:) = 0;
    MAkD(:) = 0;
    HRFC(:) = 0;

    for w = 1:num_of_epochs % w de window
        signal = double(EEG.data(ch, : , w)); % formato double para precisión (nvl. de precision de los datos grabados, por defecto)
                                              % la ventana es el numero de
                                              % ensayo o epoch
        MAA_w_c = max(abs(signal)); 
        MAA(w) = MAA_w_c;
        MAFD(w) = max(abs(diff(signal))); % Calculo y guardado de la MAFD_w_c
        kdiff = signal(indices + k) - signal(indices);
        MAkD(w) = max(abs(kdiff));

        [Pxx, f] = pwelch(signal, welch_window, noverlap, nfft, fs); 

        % Potencia por encima de 50 Hz. 
        % Calculamos potencia de frecuencia rapida.
        P_high = bandpower(Pxx, f, [50 fs/2], "psd"); % Teorema de Nyquist, NO se puede reconocer una frecuencia mayor a la mitad de la de muestreo en una grabacion discreta.
        % Potencia total
        P_total = bandpower(Pxx, f, [0 fs/2], "psd");
        HRFC(w) = P_high / P_total; % Calculamos la HRFC_c_w
    end

    % ======== Condiciones de z-score ========

    % Calculamos MAD de MAFD_c : Se calcula para todo el canal. Pues solo
    % tenemos un registro por cada epoca.

    % El factor 0.6745 escala MAD para equivaler a desviación estándar.
    sigma_fd = custom_mad(MAFD); % Nos dice donde se parte en dos el conjunto de distancias respecto a la mediana
    threshold_d = median(MAFD) + (z_MAFD_f * sigma_fd); % No estoy multiplicandolo por el factor 0.6745 !!!
    
    sigma_kd = custom_mad(MAkD);
    treshold_kd = median(MAkD) + (z_MAkD_f * sigma_kd);
    % Calculamos MAD de RFC_c
    sigma_f = custom_mad(HRFC); % Nos dice donde se parte en dos el conjunto de distancias respecto a la mediana
    threshold_f = median(HRFC) + (z_freq_f * sigma_f);

    % ========== Condiciones z-score ===================
    C1 = MAFD > threshold_d; % hace comparacion elemento a elemento 
    C2 = HRFC > threshold_f;
    C3 = MAkD > treshold_kd;
    % ========== Condiciones Predefinidas ==============
    C4 = MAA > MAA_thresh_volt;
    C5 = MAFD > amp_MAFC*(median(MAFD) + sigma_fd);
    C6 = (min_MAA_tresh < MAA) & (MAA < max_MAA_tresh) & (HRFC > amp_HRFC*(median(HRFC) + sigma_f));
    prev_selected = C4 | C5 | C6; % Guardamos los eventos ya detectados para la
    % -- Condicion basada en bandera --
    condicion = noise_matrix(ch,:) == true;
    condicion = condicion(1:end-1); % quitamos ultimo valor
    prev_selected(condicion) = true; 
    % recorremos la bandera
    b_futuro = [prev_selected(2:end), false]; % en el utlimo elem no tiene sentido evaluar, ponemos false.
    b_pasado = [false,prev_selected(1:end-1)]; % en el primer elem "", ponemos false.
    C7 = (min_MAA_tresh < MAA) & (MAA < max_MAA_tresh) & (b_pasado == true | b_futuro == true);

    noise_matrix(ch, :) = C1 | C2 | C3 | C4 | C5 | C6 | C7; 
end

% --- 2. CONDICIÓN DE COINCIDENCIA MULTICANAL ---
channels_detecting_noise = sum(noise_matrix, 1);

% Encontrar los puntos de tiempo que cumplen con el número mínimo de canales ruidosos
noisy_epochs = find(channels_detecting_noise >= channel_number_tresh);