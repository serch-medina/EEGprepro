function actualizar_registro(register_folder,register_file, ...
        new_elim_epochs,og_num_epochs)
    %ACTUALIZAR_REGISTRO - Actualiza el registro de ensayos eliminados,
    % agregando los que se eliminen en la deteccion semiautomatica de ruido
    %
    % Input arguments:
    %   register_folder - carpeta donde se guarda el registro
    %   register_file   - nombre del archivo de registro
    %   new_elim_epochs  - índices nuevos de ensayos eliminados
    %   og_num_epochs    - número original de ensayos
    %
    % Output arguments:
    %   Ninguno
    %
    arguments
        register_folder (1,:) char;
        register_file (1,:) char;
        new_elim_epochs;
        og_num_epochs (1,1);
    end
    % Preparar validaciones y mapeo entre numeración original y nueva
    % Generar un vector que nos de la correspondencia de la numeracion
    % original con la nueva, pasar los eventos eliminados en la numeracion
    % nueva a la original con la correspondencia y listo.
    
    p = numel(new_elim_epochs); % numero de nuevos ensayos eliminados

    % Validar que los índices eliminados sean enteros y estén dentro del rango
    if any(new_elim_epochs < 1 | new_elim_epochs > og_num_epochs)
        error('Los eventos eliminados contienen índices no válidos.');
    end
    % Salir sin cambios cuando no hay ensayos nuevos para registrar
    % Si no hay ensayos eliminados
    if isempty(new_elim_epochs)
        disp("Ningun ensayo fue eliminado. Registros inalterados.")
        return % Interrumpimos la ejecucion
    end
    % Construir la ruta del archivo de registro
    % 1. Define la ruta de tu archivo CSV
    register_path = fullfile(register_folder,register_file);

    if ~isfile(register_path)
        
        % Guardar directamente si el archivo aún no existe
        % Lo volvemos vertical si es horizontal
        if size(new_elim_epochs,1) == 1
            new_elim_epochs = new_elim_epochs';
        end
        writematrix(new_elim_epochs, register_path);
    else
        % Cargar el historial previo y normalizar su forma
        % Agregar los eventos
        uncompleted_epochs = readtable(register_path);
        uncompleted_epochs = uncompleted_epochs.Variables;
        og_range = 1:og_num_epochs;
        % Trabajamos todo en horizontal.
        if size(uncompleted_epochs, 2) == 1
            uncompleted_epochs = ...
                uncompleted_epochs.'; % Lo transponemos a horizontal si es 
                                      % vertical
        end
        % Partir del registro previo antes de añadir los nuevos índices
        updated_deleted_ep = ...
            uncompleted_epochs; %MATLAB crea una copia pues se modificara 
                                % updated_elim_ep
        
        new_to_original = og_range;
        new_to_original(uncompleted_epochs) = [];
        new_to_original = new_to_original(new_elim_epochs);
        updated_deleted_ep = [updated_deleted_ep new_to_original]';
        updated_deleted_ep = sort(updated_deleted_ep);
        writematrix(updated_deleted_ep, register_path);
        disp("Registro actualizado correctamente.")
    end
end

