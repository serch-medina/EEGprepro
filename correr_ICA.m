[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;
fpath_loc = fullfile('locs_canales.ced');
recortado = true; % indica si hemos generado un archivo con senhales recortadas
if recortado
    ptos_registro = 574480; % Van a cambiar si recortamos la actividad, hay que imprimir despues de recortar la actividad
else
    ptos_registro = 802951;
end
    nombre_sujeto = 'H13COM';
[fpath_act fpath_evnt]= rec_path(nombre_sujeto, recortado);
[ALLEEG EEG CURRENTSET ALLCOM] = cargar_datos_ICA(nombre_sujeto,fpath_act,fpath_evnt,fpath_loc,ptos_registro, ALLEEG,EEG,CURRENTSET,ALLCOM,NaN)
eeglab redraw 
EEG = pop_runica(EEG, 'icatype', 'fastica');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
eeglab redraw
EEG = iclabel(EEG);
EEG = pop_iclabel(EEG, 'default');
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, CURRENTSET);
pop_viewprops( EEG, 0, [1:32], {'freqrange', [2 80]}, {}, 1, 'ICLabel') 
eeglab redraw
