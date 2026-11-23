% Parametros a definir para ejecutar el ICA
fpath_loc = fullfile('locs_canales.ced');
nombre_sujeto = input('Ingrese el nombre del sujeto para realizarle el ICA\n','s');
fpath_registros = fullfile('registros/',[nombre_sujeto '_registro_preprocesamiento.txt']);
recortado = false; % indica si hemos generado un archivo con senhales recortadas

% Extraccion de numero de puntos 
ptos_registro = extraer_puntos(fpath_registros,nombre_sujeto,recortado);

% Inicio de eeglab
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab; 
% extraccion de rutas de archivos de eventos y actividad
[fpath_act, fpath_evnt]= rec_path(nombre_sujeto, recortado);
% Cargado de datos del dataset en eeglab y ejecucion del ICA
[ALLEEG EEG CURRENTSET ALLCOM] = cargar_datos_ICA(nombre_sujeto,fpath_act,fpath_evnt,fpath_loc,ptos_registro, ALLEEG,EEG,CURRENTSET,ALLCOM,NaN)
eeglab redraw 
EEG = pop_runica(EEG, 'icatype', 'fastica'); % ejecucion de ICA
noc = size(EEG.icawinv, 2); % noc: number of ica components
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET); % Sobreescribe los datos del ICA en el dataset actual.
eeglab redraw
EEG = iclabel(EEG, 'default'); % Por que puse la linea repetida dos veces, solo una es con la GUI? 
EEG = pop_iclabel(EEG, 'default');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
% - El segundo argumento es si se usan componentes (=0) o canales (=1) 
% - El ultimo argumento es el gestor de componentes que se usara
pop_viewprops(EEG, 0, 1:noc, {'freqrange', [2 80]}, {}, 1, 'ICLabel') 
eeglab redraw
