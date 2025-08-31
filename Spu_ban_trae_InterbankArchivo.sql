ALTER procedure Spu_ban_trae_InterbankArchivo      
@Ban01Empresa varchar(2),    
@Ban01Numero varchar(5)    
as      
Begin      
    
   SELECT       
    '02' AS CodigoRegistro,      
    BPD.Ban02Ruc + REPLICATE('0', 20-LEN(BPD.Ban02Ruc)) AS CodigoBeneficiario,      
    (case BPD.Ban02Tipodoc when '01' then 'F' Else 'O' end) AS TipoDocumentoPago,      
    replace(BPD.Ban02NroDoc,'-','') + replicate('0',20-len(replace(BPD.Ban02NroDoc,'-',''))) AS NumeroDocumentoPago,  
     '',  
    (case ''  
     when  'D' then '10' else '01' end) AS MonedaAbono,           
     (case '' when 'D' then dbo.ConvertirFormatoAbono(0)      
     else dbo.ConvertirFormatoAbono(0) end)      
    AS MontoAbono,      
    --BPD.Ban02NetoDolares,      
    '' AS IndicadorBanco,      
         
    '09' AS TipoAbono,          
    '' as TipoCuenta,      
     
    CASE       
     WHEN LEN(BPD.Ban02Ruc) = 11 THEN '2'       
     ELSE '1'       
    END AS TipoPersona,      
         
    BPD.Ban02Tipodoc AS TipoDocumentoIdentidad,      
    BPD.Ban02Ruc AS NumeroDocumentoIdentidad,      
    --BPD.Ban02GiroOrden AS NombreBeneficiario,      
    NULL AS MonedaMontoIntangibleCTS,      
    NULL AS MontoIntangibleCTS,      
         
    -- Filler vacío      
    '' AS Filler,      
         
    -- Celular      
    NULL AS NumeroCelular,      
         
    -- Correo      
    NULL AS CorreoElectronico      
         
   FROM   Ban02PresupuestoPagoDetalle BPD      
    INNER JOIN Ban01PresupuestoPago PP       
     ON BPD.Ban02Numero = PP.Ban01Numero       
       AND BPD.Ban02Empresa = PP.Ban01Empresa      
   Where    
   PP.Ban01Empresa = @Ban01Empresa  
   And PP.Ban01Numero  = @Ban01Numero  
     
End 