CREATE TABLE CLIENTE 
(id_cliente NUMBER(10) CONSTRAINT PK_CLIENTE PRIMARY KEY, 
 nombre_cliente VARCHAR2(50)  NOT NULL, 
 fecha_incorporacion DATE  NOT NULL);

CREATE TABLE EMPLEADO
(rut_empleado NUMBER(10) CONSTRAINT PK_EMPLEADO PRIMARY KEY,
 dv_rut_empleado VARCHAR2(1) NOT NULL,
 nombre_empleado VARCHAR2(50) NOT NULL,
 fecha_contrato DATE);

CREATE TABLE FACTURA 
(nro_factura NUMBER(10) CONSTRAINT PK_FACTURA PRIMARY KEY , 
 fecha DATE  NOT NULL , 
 monto_total NUMBER(15)  NOT NULL , 
 cantidad_cuotas NUMBER(2)  NOT NULL , 
 id_cliente NUMBER(10) NOT NULL,
 rut_empleado NUMBER(10) NOT NULL,
 CONSTRAINT FK_FACTURA_CLIENTE FOREIGN KEY(id_cliente) REFERENCES CLIENTE(id_cliente),
 CONSTRAINT FK_FACTURA_EMPLEADO FOREIGN KEY(rut_empleado) REFERENCES EMPLEADO(rut_empleado)); 
 
CREATE TABLE CUOTA 
(nro_factura NUMBER(10) NOT NULL, 
 nro_cuota NUMBER(2)  NOT NULL , 
 valor_cuota NUMBER(10)  NOT NULL , 
 fecha_vencimiento DATE  NOT NULL,
 CONSTRAINT PK_CUOTA PRIMARY KEY(nro_factura,nro_cuota),
 CONSTRAINT FK_CUOTA_FACTURA FOREIGN KEY (nro_factura) REFERENCES FACTURA(nro_factura));


CREATE TABLE VENTA_EMPLEADO
 (rut_empleado NUMBER(10) CONSTRAINT PK_VENTA_EMPLEADO PRIMARY KEY,
  total_venta  NUMBER(10) NOT NULL,
  monto_total_ventas  NUMBER(10) NOT NULL,
  CONSTRAINT FK_VENTA_EMP_EMPLEADO FOREIGN KEY (rut_empleado) REFERENCES EMPLEADO(rut_empleado));
  
CREATE TABLE TOTAL_PESOS_COMPRAS
(id_cliente NUMBER(10) CONSTRAINT PK_TOTAL_PESOS_COMPRA PRIMARY KEY,
 total_pesos  NUMBER(10) NOT NULL,
 CONSTRAINT FK_TOTAL_PCOMPRAS_CLIENTE FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente));
 
 CREATE TABLE DETALLE_PESOS_COMPRAS
 (id_cliente NUMBER(10) NOT NULL,
  nro_factura NUMBER(10) NOT NULL,
  pesos_factura  NUMBER(10) NOT NULL,
  CONSTRAINT PK_DETALLE_PESOS_COMPRAS PRIMARY KEY(id_cliente, nro_factura),
  CONSTRAINT FK_DETPESOS_FACTURA FOREIGN KEY (nro_factura) REFERENCES FACTURA(nro_factura),
  CONSTRAINT FK_DETPESOS_CLIENTE FOREIGN KEY (id_cliente) REFERENCES CLIENTE(id_cliente));
  
INSERT INTO CLIENTE VALUES(3456,'Pedro Pérez Pereira','05/03/2021');
INSERT INTO CLIENTE VALUES(9862,'Sandra Soto Sevilla','01/10/2021');
INSERT INTO CLIENTE VALUES(7777,'Juan Tapia Molina','14/12/2022');
INSERT INTO CLIENTE VALUES(9999,'María Moreno Elgueta','05/05/2023');

INSERT INTO EMPLEADO VALUES(1111111, 1, 'Marcos Ramirez Ponce', '01/01/2020');
INSERT INTO EMPLEADO VALUES(2222222, 2, 'Marcela Rondini Flores', '05/01/2021');
INSERT INTO EMPLEADO VALUES(3333333, 3, 'Claudio Armijo Buljan', '05/05/2023');

INSERT INTO FACTURA VALUES(1,'21/03/2023',34560,3,3456, 1111111);
INSERT INTO FACTURA VALUES(2,'13/03/2023',457893,5,9862, 1111111);
INSERT INTO FACTURA VALUES(3,'05/05/2023',600000,2,9999, 1111111);
INSERT INTO FACTURA VALUES(4,'16/05/2023',558000,3,9862, 2222222);

INSERT INTO CUOTA VALUES(1,1,11520,'21/04/2023');
INSERT INTO CUOTA VALUES(1,2,11520,'21/05/2023');
INSERT INTO CUOTA VALUES(1,3,11520,'21/06/2023');
INSERT INTO CUOTA VALUES(2,1,91585,'13/04/2023');
INSERT INTO CUOTA VALUES(2,2,91577,'13/05/2023');
INSERT INTO CUOTA VALUES(2,3,91577,'13/06/2023');
INSERT INTO CUOTA VALUES(2,4,91577,'13/07/2023');
INSERT INTO CUOTA VALUES(2,5,91577,'13/08/2023');
INSERT INTO CUOTA VALUES(3,1,300000,'05/06/2023');
INSERT INTO CUOTA VALUES(3,2,300000,'05/07/2023');
INSERT INTO CUOTA VALUES(4,1,186000,'16/06/2023');
INSERT INTO CUOTA VALUES(4,2,186000,'16/07/2023');
INSERT INTO CUOTA VALUES(4,3,186000,'16/08/2023');
COMMIT;









-----------------------------------------------------------------------------------------------------------------------------------
--REQUERIMIENTO 1

--HABILITACION MENSAJES
SET SERVEROUTPUT ON;

--PROCESO DE INGRESO -- PRIMER PASO 
CREATE OR REPLACE PROCEDURE SP_FACTURAS_CLIENTE(
    p_id_cliente OUT NUMBER,
    p_nro_factura IN NUMBER,
    p_peso_factura OUT NUMBER
) IS
BEGIN
    -- Seleccionar el cliente y calcular el peso acumulado
    SELECT id_cliente, ROUND(monto_total * 0.125) -- 12.5% de la compra, redondeado
    INTO p_id_cliente, p_peso_factura
    FROM FACTURA
    WHERE nro_factura = p_nro_factura;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Si no se encuentra la factura, se maneja el error
            DBMS_OUTPUT.PUT_LINE('No se encontró la factura con el número ' || p_nro_factura);
        WHEN OTHERS THEN
            -- Captura cualquier otro tipo de error
            DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END SP_FACTURAS_CLIENTE;
/


--PROCESO DE SALIDA -- SEGUNDO PASO
CREATE OR REPLACE PROCEDURE SP_SALIDA IS
    -- DEFINICION DE CURSOR PARA FACTURAS 
    CURSOR cur_factura IS
        SELECT nro_factura
        FROM FACTURA;
        
    -- ALMACENAMIENTO RESULTADOS
    v_id_cliente FACTURA.ID_CLIENTE%TYPE;
    v_peso_factura NUMBER(7) := 0;
BEGIN
    
    FOR reg_factura IN cur_factura LOOP
        
        SP_FACTURAS_CLIENTE(v_id_cliente, reg_factura.nro_factura, v_peso_factura);
        
        INSERT INTO DETALLE_PESOS_COMPRAS (ID_CLIENTE, NRO_FACTURA, PESOS_FACTURA)
        VALUES (v_id_cliente, reg_factura.nro_factura, v_peso_factura);
    END LOOP;

    
    FOR reg_cliente IN (SELECT id_cliente FROM CLIENTE) LOOP
        
        MERGE INTO TOTAL_PESOS_COMPRAS tpc
        USING (SELECT id_cliente, SUM(pesos_factura) AS total_pesos
               FROM DETALLE_PESOS_COMPRAS
               WHERE id_cliente = reg_cliente.id_cliente
               GROUP BY id_cliente) src
        ON (tpc.id_cliente = src.id_cliente)
        WHEN MATCHED THEN
            UPDATE SET tpc.total_pesos = src.total_pesos
        WHEN NOT MATCHED THEN
            INSERT (id_cliente, total_pesos)
            VALUES (src.id_cliente, src.total_pesos);
    END LOOP;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontraron datos para procesar.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END SP_SALIDA;
/

--EJECUCION PROCEDIMIENTO DE SALIDA
BEGIN
    SP_SALIDA;
END;

-- CONSULTA DE TABLAS
SELECT * FROM DETALLE_PESOS_COMPRAS ORDER BY PESOS_FACTURA ASC;
SELECT * FROM TOTAL_PESOS_COMPRAS;


----------------------------------------------------------------------------------------------------------------------------------

--REQUERIMIENTO 2 

CREATE OR REPLACE FUNCTION CALCULA_COMISION(p_rut_empleado IN NUMBER) 
RETURN NUMBER
IS
    v_monto_total NUMBER(10);  -- Variable para almacenar el total de ventas del empleado
    v_comision NUMBER(10);      -- Variable para almacenar la comisión calculada
BEGIN
    -- Calculamos el total de las facturas del empleado
    SELECT NVL(SUM(monto_total), 0)
    INTO v_monto_total
    FROM FACTURA
    WHERE rut_empleado = p_rut_empleado;

    -- Si hay ventas, calculamos la comisión; de lo contrario, la comisión es 0
    IF v_monto_total > 0 THEN
        v_comision := v_monto_total * 0.183;  -- 18.3% de comisión
    ELSE
        v_comision := 0;  -- Si no tiene ventas, la comisión es 0
    END IF;

    -- Retornamos el valor de la comisión calculada
    RETURN v_comision;
EXCEPTION
    WHEN OTHERS THEN
        -- Manejo de errores
        RETURN 0;  -- Retorna 0 en caso de error
END CALCULA_COMISION;


--CONSULTA PARA MOSTRAR LA FUNCION
SELECT rut_empleado, CALCULA_COMISION(rut_empleado) AS comision FROM EMPLEADO;



























