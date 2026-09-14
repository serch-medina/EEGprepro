function mad = custom_mad(datos, mdian)
    % CUSTOM_MAD Calcula la Desviacion Absoluta de la Mediana o de la Media
    %       CUSTOM_MAD Calcula la Desviacion Absoluta de la Mediana por
    %       defecto, multiplicando por un factor de 1/0.6745. Acepta
    %       unicamente vectores unidimensionales.
    %       Sintaxis: 
    %           mad = custom_mad(datos, median).
    %
    %       Argumento de entrada:
    %           datos - datos de la senhal eeg (vector).
    %           median - bandera que indica si calcular mediana o media, 
    %                    true por defecto (bool).
    %       Salida:
    %           mad - valor de la mad calculada.
    arguments
        datos (1,:); % acepta solo vectores
        mdian logical = true;
    end
    if mdian
        med = median(datos);
        mad = median(abs(datos - med)) / 0.6745;
    else
        med = mean(datos);
        mad = mean(abs(datos - med));
    end
end