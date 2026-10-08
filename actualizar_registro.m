function actualizar_registro(register_folder,register_file, ...
        new_elim_epochs,og_num_epochs)
    arguments
        register_folder (1,:) char;
        register_file (1,:) char;
        new_elim_epochs;
        og_num_epochs (1,1);
    end
    % Generar un vector que nos de la correspondencia de la numeracion
    % original con la nueva, pasar los eventos eliminados en la numeracion
    % nueva a la original con la correspondencia y listo.
    
    p = numel(new_elim_epochs); % numero de nuevos ensayos eliminados

    % Validar que los índices eliminados sean enteros y estén dentro del rango
    if any(new_elim_epochs < 1 | new_elim_epochs > og_num_epochs)
        error('Los eventos eliminados contienen índices no válidos.');
    end
    % Si no hay ensayos eliminados
    if isempty(new_elim_epochs)
        disp("Ningun ensayo fue eliminado. Registros inalterados.")
        return % Interrumpimos la ejecucion
    end
    % 1. Define la ruta de tu archivo CSV
    register_path = fullfile(register_folder,register_file);

    if ~isfile(register_path)
        
        % Lo volvemos vertical si es horizontal
        if size(new_elim_epochs,1) == 1
            new_elim_epochs = new_elim_epochs';
        end
        writematrix(new_elim_epochs, register_path);
    else
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
