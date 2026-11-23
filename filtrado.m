% Pendiente convertir a funcion con esta y otra funcion mas que emule el
% comportamiento del python, tecnicamente ya tendriamos el preprocesamiento
% armado en matlab completo y mucho mas sencillo. 
data_double = double(EEG.data); 

fs = EEG.srate;

f_low = 0.5;
f_high = 50;

% Frecuencias normalizadas
Wn = [f_low f_high] / (fs/2);

% Butterworth pasabanda, prototipo de orden 4 x 2 
    % Tanto en python como en Matlab se especifíca que el orden de pasa y
    % elimina banda, se duplica.
[b,a] = butter(4, Wn, 'bandpass');

[n_chans, n_pnts, n_epochs] = size(data_double);

for ep = 1:n_epochs 
    for ch = 1:n_chans 
        % Filtrado causal
        data_double(ch, :, ep) = filter(b, a, data_double(ch, :, ep)); 
    end 
end 

EEG.data = single(data_double);
eeg_checkset(EEG);

clear n_pnts n_chans n_epochs Wn fs b a data_double
eeglab redraw

%data_double