
--select  * from Ban02PresupuestoPagoDetalle where Ban02Numero = '00004'
--select * from ccm04ctabancaria
----ccm04bancocod

----ccm04entidadcod

----ccm04bancocod
----01

----ccm04nrocuenta
----ccm04nrocuentacci

----select SUBSTRING('' len('8983207873775')
----select SUBSTRING('8983207873775522885',4,LEN('8983207873775522885')) 
----select len('8983207873595')
--select * From sys.objects where type = 'p'
--and name like '%interbank%'
--order by modify_date desc
-- exec Spu_ban_trae_InterbankCabArchivo  '01', 'Prov072025', '00004'


--select * From Ban02PresupuestoPagoDetalle
alter procedure Spu_ban_trae_InterbankCabArchivo  
@codigoEmpresa char(2),  
@nombreLote varchar(12),  
@numeroPresupuesto varchar(5)  
  
as  
Begin  
  ---cabecera documento   
  declare @nombreSolicitudLote as varchar(12)  
  set @nombreSolicitudLote = @nombreLote  
  --select @nombreSolicitudLote  
    
  declare @fechadt as datetime = GETDATE()  
  declare @fechatxt as varchar(10) = convert(varchar(10),@fechadt, 103)  
  declare @horatxt as varchar(8) = convert(varchar(10),@fechadt, 108)  
  --dd/MM/yyyy  
  declare @fechaHoraCreacion as varchar(14)  
  select @fechaHoraCreacion = SUBSTRING(@fechatxt, 7,4) + SUBSTRING(@fechatxt, 4,2)+ SUBSTRING(@fechatxt, 1, 2)   
  +SUBSTRING(@horatxt, 1,2) + SUBSTRING(@horatxt, 4,2) + SUBSTRING(@horatxt,7,2)  
  --select @fechaHoraCreacion  
    
  -- nro de registro del presupuesto  
  declare @nroRegistro as varchar(6)  
    
  declare @totalSoles decimal(13,2)  
  declare @totalDolares decimal(13,2)  
    
    
 select    
 @nroRegistro = convert(varchar(6),isnull(COUNT(PP.Ban01Numero),0))   ,   
 @totalSoles  = isnull(sum(bpd.Ban02Soles),0),   
 @totalDolares =  isnull(SUM(bpd.ban02dolares),0)   
 FROM   Ban02PresupuestoPagoDetalle BPD      
    INNER JOIN Ban01PresupuestoPago PP       
     ON BPD.Ban02Numero = PP.Ban01Numero       
       AND BPD.Ban02Empresa = PP.Ban01Empresa          
                  
   Where    
   PP.Ban01Empresa = @codigoEmpresa    
   And PP.Ban01Numero  = @numeroPresupuesto  
     
   --select dbo.ConvertirFormatoAbono(@totalSoles) as 'TotalSoles',  @totalSoles as '@totalSoles',  
   --dbo.ConvertirFormatoAbono(@totalDolares) as 'TotalDolares', @totalDolares as '@totalDolares'  
     
-----------------------------------------------------------------------  
declare @nroRegistrosTexto as varchar(6)  
declare @totalSolesTexto as varchar(15)  
declare @totalDolaresTexto as varchar(15)  
  
 select @nroRegistrosTexto = replicate('0',   
        6-len(@nroRegistro))  
        + rtrim(ltrim(STR(@nroRegistro)))  
  , @totalSolesTexto = dbo.ConvertirFormatoAbono(@totalSoles)   
  , @totalDolaresTexto = dbo.ConvertirFormatoAbono(@totalDolares)  
    
declare @codigoEmpresaInterbank as varchar(4)  
set @codigoEmpresaInterbank  ='0001'  
  
declare @codigoservicioInterbank as varchar(2)  
set @codigoservicioInterbank  = '01'  
---------------------------------------  
  select '01' as codigoRegistro, -- codigoregistro L:2  
   '03' as rubro -- 03:proveedores  L:2  
  ,@codigoEmpresaInterbank as codigoEmpresa, -- L:4  
  @codigoservicioInterbank as 'codigoServicio' , -- L:2  
   TP.Ban01CtaBanCod as 'cuentaCargo', -- L:13  
   '001' as 'tipoCuentaCargo', -- 001 cuenta corriente , 002 cuenta ahorro L:3  
   (case TP.ban01moneda  
  when 'S' then '01' else '10' end) --   
  as 'monedaCuentaCargo' ,  -- 01 soles , 10 dolares  L:2  
   Replicate(' ',12-LEN(@nombreSolicitudLote))  +@nombreSolicitudLote  as 'nombreSolicitudLote' -- L:12  
     
   ,@fechaHoraCreacion 'fechahoraCreacion'-- L:14  
   ,'0' as 'tipoProceso' -- 0 : en linea, 1: en diferido   
    ,SUBSTRING(@fechatxt, 7,4) +   
    SUBSTRING(@fechatxt, 4,2)+   
    SUBSTRING(@fechatxt, 1, 2) as 'fechaProceso'   --Si tipo de proceso en línea,   
    --la fecha es del día enviado. Si es Diferido la fecha es futura, no Domingos ni feriados. L: 8  
      
   , @nroRegistrosTexto as 'nroRegistro' -- L:6  
   ,@totalSolesTexto as 'totalSoles' -- L:15  
   ,@totalDolaresTexto as 'totalDolares' -- L:15  
   ,'MC001' as versionMacro  
   from Ban01TipoPago TP         
    LEFT JOIN Ban01CuentaBancaria CB    
     ON TP.Ban01Empresa = CB.Ban01Empresa     
     And TP.Ban01CtaBanBancoCod = CB.Ban01IdCuenta    
     And TP.Ban01CtaBanCod = CB.Ban01IdBanco    
   --select * from Ban01CuentaBancaria  
   where tp.Ban01Empresa = @codigoEmpresa --empresa minera deisi  
   and tp.Ban01IdTipoPago = '04' -- interbank soles  
     
  End  
  
  
alter procedure Spu_Ban_Trae_InterbankDetArchivo
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
  and ctabcoProv.ccm04ctadefecto = 'S' and Ban01IdTipoPago = '04') -- empresa 01 , banco interbank pago soles 04
  

 SELECT     
    '02' AS 'codigoRegistro',
    presupuestoDet.Ban02Ruc + REPLICATE(' ', 20-LEN(presupuestoDet.Ban02Ruc)) AS 'codigoBeneficiario',
    (case presupuestoDet.Ban02Tipodoc when '01' then 'F' Else 'O' end) AS 'tipoDocumentoPago',    
    replace(presupuestoDet.Ban02NroDoc,'-','') 
    + replicate(' ',20-len(replace(presupuestoDet.Ban02NroDoc,'-',''))) AS 'numeroDocumentoPago',    
    
     --BPD.Ban02FechaVencimiento    
     right(presupuestoDet.Ban02FechaVencimiento, 4)           
      + SUBSTRING(presupuestoDet.Ban02FechaVencimiento, 4,2) 
      +SUBSTRING(presupuestoDet.Ban02FechaVencimiento, 1,2) as 'fechaVencimientoDocumento',    
        
    --   CONVERT(VARCHAR(10), BPD.Ban02FechaVencimiento, 121) AS FechaVencimiento,    
       
    (case presupuestoDet.Ban02Moneda     
     when  'D' then '10' else '01' end) AS 'monedaAbono',    
           
     --  select  replicate('0', 13- len(replace((case BPD.Ban02Moneda    
     --when 'D' then convert(varchar(13),BPD.Ban02NetoDolares)     
     --else convert(varchar(13),BPD.Ban02NetoSoles)     
     --  end ),'.',''))) + replace(@importeTexto,'.','') 
        
     (case presupuestoDet.Ban02Moneda when 'D' 
     then dbo.ConvertirFormatoAbono(presupuestoDet.Ban02NetoDolares)    
     else dbo.ConvertirFormatoAbono(presupuestoDet.Ban02NetoSoles) end)    
    AS 'montoAbono',    
    --BPD.Ban02NetoDolares,    
    ' ' AS 'indicadorBanco',    
       
       --Tipo de abono
       cteAbono.TipoAbono as 'tipoAbaono',
       
       
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
, (case when cteAbono.TipoAbono = '09' 
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
       when  '6' then '01' 
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

