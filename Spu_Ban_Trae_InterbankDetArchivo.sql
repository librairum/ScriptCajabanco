ALTER procedure Spu_Ban_Trae_InterbankDetArchivo    
@codigoEmpresa char(2),    
@numeroPresupuesto varchar(5)    
as    
Begin    
    
--------cte tipo abono    
with CteTipoAbono as (    
select Ban01IdTipoPago,    
   ctabcoProv.ccm04entidadcod as numeroDocIdentidad,     
 (case when mediopago.Ban01IdTipoPago = '01'  -- cheque     
 then '11' else      
  (case     
   when ctabcoProv.ccm04bancocod = mediopago.Ban01CtaBanBancoCod  -- si es mismo banco interbank    
    then '09'     
    else '99'  -- interbancario    
   end)    
  end) as TipoAbono    
    from ccm04ctabancaria ctabcoProv    
  inner join Ban01TipoPago mediopago    
  on ctabcoProv.ccm04emp = mediopago.Ban01Empresa    
  and ctabcoProv.ccm04bancocod = mediopago.Ban01CtaBanBancoCod    
  where ctabcoProv.ccm04emp = '01'  
  --where ctabcoProv.ccm04emp = @codigoEmpresa    
  and ctabcoProv.ccm04ctadefecto = 'S'     
and Ban01IdTipoPago = '04') -- empresa 01 , banco interbank pago soles 04    
      
    
 SELECT         
    '02' AS 'codigoRegistro',    
    presupuestoDet.Ban02Ruc + REPLICATE(' ', 20-LEN(presupuestoDet.Ban02Ruc)) AS 'codigoBeneficiario',    
    (case presupuestoDet.Ban02Tipodoc when '01' then 'F' Else 'O' end) AS 'tipoDocumentoPago',        
    replace(presupuestoDet.Ban02NroDoc,'-','')     
    + replicate(' ',20-len(replace(presupuestoDet.Ban02NroDoc,'-',''))) AS 'numeroDocumentoPago',        
        
        
      '',        
            
        
           
    (case '' --presupuestoDet.Ban02Moneda         
     when  'D' then '10' else '01' end) AS 'monedaAbono',        
               
    
            
     (case '' --presupuestoDet.Ban02Moneda 
	 when 'D'     
     then dbo.ConvertirFormatoAbono(0)        
     else dbo.ConvertirFormatoAbono(0) end)        
    AS 'montoAbono',        
        
    ' ' AS 'indicadorBanco',        
           
       --Tipo de abono    
    
    
       cteAbono.TipoAbono as 'tipoAbono',    
           
           
(case  when cteAbono.TipoAbono = '09'      
then      
 (case     
 when ctabcoProv.ccm04tipocuenta = 'C'      
 then '001'    
 when  ctabcoProv.ccm04tipocuenta = 'A'     
 then '002' else ''     
 end)    
 when cteAbono.TipoAbono = '09' then ''    
 when cteAbono.TipoAbono = '11' then ''    
   else '' end) as  'tipoCuenta'      
    
,(case when cteAbono.TipoAbono = '09' then     
 (    
  (case when ccm04moneda = 'S' then '01' else '10' end)    
    
 )    
 when cteAbono.TipoAbono = '99' then ''    
 when cteAbono.TipoAbono = '11' then ''    
 end) as 'monedaCuenta'    
 ,  (case when  cteAbono.TipoAbono = '09'     
 then substring(ccm04nrocuenta,1,3)    
     
 when  cteAbono.TipoAbono = '99' then ''     
 when  cteAbono.TipoAbono = '11' then ''     
 else ''    
 end)  as 'oficinaCuenta'    
,     
    
    
(case when cteAbono.TipoAbono = '09'     
   then (SUBSTRING(ccm04nrocuenta,4,LEN(ccm04nrocuenta))     
       + REPLICATE(' ',    
       20- len(SUBSTRING(ccm04nrocuenta,4,LEN(ccm04nrocuenta))))    
      )    
  when cteAbono.TipoAbono = '99'     
   then  ccm04nrocuentacci+REPLICATE(' ',20- len(ccm04nrocuentacci))    
   else replicate(' ',20) end) as 'numeroCuenta',    
 --Tipo de persona    
 (case proveedor.ccm02TipoRuc     
  when  '1' then 'P'     
  when  '2' then 'C'    
  end) as 'tipoPersona',    
       (case ccm02tipdocidentidad     
       when    
    
  '6' then '01'     
       when '1' then '02'    
       else '03' end) as 'tipoDocumentoIdentidad',    
          
       ccm02ruc + REPLICATE(' ', 15 - LEN(ccm02ruc)) as 'numeroDocumentoIdentidad' ,    
       ccm02nom+replicate(' ', 60 - len(ccm02nom)) as 'nombreBeneficiario',    
           
       replicate(' ',2) as 'monedaMontoIntagibleCTS',    
       replicate(' ', 15) as  'montoIntangibleCTS',    
       replicate(' ',6) as  'filler',    
            
     
    -- Celular        
    replicate(' ',40) AS 'numeroCelular',        
           
    -- Correo        
    ccm02correo + replicate(' ', 140+LEN(ccm02correo)) AS 'correoElectronico'    
           
   FROM   Ban02PresupuestoPagoDetalle presupuestoDet        
    INNER JOIN Ban01PresupuestoPago prespuestoCab    
     ON presupuestoDet.Ban02Numero = prespuestoCab.Ban01Numero         
       AND presupuestoDet.Ban02Empresa = prespuestoCab.Ban01Empresa                  
         
     left join ccm04ctabancaria ctabcoProv -- cta bancaria Proveedor    
     on presupuestoDet.Ban02Empresa = ctabcoProv.ccm04emp    
     and presupuestoDet.Ban02Ruc = ctabcoProv.ccm04entidadcod    
     and ctabcoProv.ccm04ctadefecto = 'S'    
         
     left join ccm02cta proveedor    
     on proveedor.ccm02emp = ctabcoProv.ccm04emp    
 and proveedor.ccm02cod = ctabcoProv.ccm04entidadcod    
 and proveedor.ccm02tipana = ctabcoProv.ccm04tipana    
 and ctabcoProv.ccm04ctadefecto = 'S'    
      
 left join Ban01Banco banco     
 on banco.Ban01Empresa = ctabcoProv.ccm04emp    
 and banco.Ban01IdBanco = ctabcoProv.ccm04bancocod    
     
 LEFT join CteTipoAbono  cteAbono    
 on cteAbono.numeroDocIdentidad = ctabcoProv.ccm04entidadcod    
     
   Where         
   prespuestoCab.Ban01Empresa = @codigoempresa    
   And prespuestoCab.Ban01Numero=@numeroPresupuesto    
    
    
End    