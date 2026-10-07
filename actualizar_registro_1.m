function actualizar_registro_1(register_folder,register_file,added_elim_epochs)
    % Lo que hace la funcion es que agrega al registro de epocas eliminadas
    % las que se quiten en la eliminacion de epocas ruidosas llevado a cabo
    % durante la ejecucion de 'correr_ruido.m'. Esto permite quitar las de
    % forma automatica las epocas con ruido del archivo .MAT 
    % de la psicometrica
    arguments
        register_folder (1,:) char;
        register_file (1,:) char;
        added_elim_epochs;
    end
        
    p = length(added_elim_epochs);

    % 1. Define la ruta de tu archivo CSV
    full_path_reg = fullfile(register_folder,register_file);

    % Mas bien hay que verificar si el archivo existe, puesto que si no se
    % detectan eventos incompletos el registro no se crea. Si el archivo no
    % existe entonces hay que crear uno en caso de que haya eventos
    % eliminados y hay que dejar todo igual (no crear nuevos archivos si no 
    % se elimina nada).

    % 3. Verifica si el archivo existe
    if ~isfile(full_path_reg) % Si no existe:
        % Vamos a agregar las epocas eliminadas directamente. Osea, verter
        % el noisy_epochs
        if size(added_elim_epochs, 1) == 1
            added_elim_epochs = added_elim_epochs.'; % Lo transponemos a vertical si era horizontal
        end
        writematrix(added_elim_epochs, fullfile('ensayos_por_eliminar','datos_vertical.csv')); % RUTA DE PRUEBA MODIFICAR !!!
    else
        % 2. Lee el archivo como una tabla
        uncompleted_epochs = readtable(full_path_reg);
        uncompleted_epochs = uncompleted_epochs.Variables;
        updated_elim_ep = uncompleted_epochs; %MATLAB crea una copia pues se 
                                              % modificara updated_elim_ep
        % Si no esta vacia 
        k = length(uncompleted_epochs); % datos eliminados en el prepro
        j = 1;
        for l = j:k
            ml = uncompleted_epochs(l);
            for i=1:p % SI SOLO ES UNO QUE VA ANTES, ESTO SOLO PROVOCA UNA ITERACION EN ESTE BUCLE (COMO SI NO HUBIERA BUCLE
                ni = added_elim_epochs(i);
                if (ml > ni) %&& (l == j)
                    disp("Hola ml < ni %% l == j")
                    % Agregamos 'ni' al registro de eliminados. No hace
                    % falta sumar 1. Coinciden.
                    updated_elim_ep(end + 1) = ni;
                    disp(updated_elim_ep)
                    if j < k % verificacion necesaria por el caso k=1
                        j = j+1;
                    end
                elseif ml > ni
                    updated_elim_ep(end + 1) = ni;
                    if j < k % verificacion necesaria por el caso k=1
                        j = j+1;
                    end
                    break;
                elseif ml <= ni
                    disp("Hola ml <= ni")
                    added_elim_epochs(i:p) = added_elim_epochs(i:p) + 1;
                    disp(added_elim_epochs)
                end
                fprintf('%d',l)
            end
        end
        updated_elim_ep = sort(updated_elim_ep);
        % Nos aseguramos de que sea un vector columna (vertical)
        if size(updated_elim_ep, 1) == 1
            updated_elim_ep = updated_elim_ep.'; % Lo transponemos a vertical si era horizontal
        end
        disp("Vamos a exportar")
        disp(added_elim_epochs)
        updated_elim_ep
        % 3. Exportamos directamente a un archivo .csv De momento ruta
        % diferente para no sobreescribir.
        writematrix(updated_elim_ep, fullfile('ensayos_por_eliminar','datos_vertical.csv')); % RUTA DE PRUEBA MODIFICAR !!!
    end
end