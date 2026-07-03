function [fpath_act, fpath_evnt] = rec_path(nombre_sujeto, recortar)
    % Funcion para uso interno. Se le pasa el nombre
    % del archivo e internamente reconstruye la ruta de los
    % archivos de actividad y eventos exportados por python,
    % de tal forma, no hace falta escribir la ruta completa
    arguments
        nombre_sujeto (1,:) char;
        recortar (1,1) = false;
    end
    % se guardan las rutas de los directorio donde se encuentran los archivos 
    dpath_act = fullfile('datos_exportados_py/','actividad_filtrada');
    dpath_evnt = fullfile('datos_exportados_py/','eventos_modificados/');
    % se unen con el nombre del sujeto para construir la ruta final
    if recortar
        fname_act = [nombre_sujeto,'_actividad_filtrada_rec'];
        fname_evnt = [nombre_sujeto,'_eventos_modificados_rec.csv'];
    else
        fname_act = [nombre_sujeto,'_actividad_filtrada'];
        fname_evnt = [nombre_sujeto,'_eventos_modificados.csv'];
    end
    fpath_act = fullfile(dpath_act,fname_act);
    fpath_evnt = fullfile(dpath_evnt,fname_evnt);
end