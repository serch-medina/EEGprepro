function [ALLEEG EEG CURRENTSET ALLCOM] = cargar_datos_ICA(nombre_sujeto,fpath_act,fpath_evnt,fpath_loc,ptos_registro,ALLEEG,EEG,CURRENTSET,ALLCOM,unidad,campos_eventos,srate,nbchan)

    % Espera en fpath_sujeto la ruta completa del archivo donde se guarda 
    % la información de actividad del sujeto.
    % fpath_loc Indica la ruta para el canal de localizaciones.
    % ptos_registro espera un entero e indica las samples de las que se
    % compone el registro
    % unidades Unidad en que estan expresados los eventos, 1 corresponde a
    % segundos y NaN a samples.

    arguments
        nombre_sujeto (1,:) char;
        fpath_act (1,:) char;
        fpath_evnt (1,:) char;
        fpath_loc (1,:) char;
        ptos_registro (1,1) {mustBeNumeric};
        ALLEEG;
        EEG;
        CURRENTSET;
        ALLCOM;
        unidad (1,1) = 1;
        campos_eventos = {'latency','type','urevent','duration'};
        srate (1,1)  {mustBeNumeric} = 250; % Set the sampling rate for the EEG data
        nbchan (1,1)  {mustBeNumeric} = 32;
        
    end
    
    nombre_dataset = [nombre_sujeto,'_prepropython'];
    EEG = pop_importdata('dataformat','ascii','nbchan',nbchan,'data',fullfile(fpath_act),'setname',nombre_dataset,'srate',srate,'pnts',ptos_registro,'xmin',0,'chanlocs',fullfile(fpath_loc));
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
    EEG = pop_importevent( EEG,'append','no', 'event',fullfile(fpath_evnt),'fields',campos_eventos,'skipline',1,'timeunit',unidad); %timeunit indica 1 = 1 segundo, NaN = samples
    
    % Reescribimos los datos que ya teniamos
    [ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'overwrite', 'on', 'gui', 'on'); 

    % pop_eegplot(EEG, 1, 1, 1)
end