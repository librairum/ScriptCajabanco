CREATE procedure Spu_ban_trae_InterbankCabArchivo      
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
 @totalSoles  = 0,       
 @totalDolares =  0       
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
  @codigoservicioInterbank as 'codigoservicio' , -- L:2      
   TP.Ban01CtaBanCod as 'cuentacargo', -- L:13      
   '001' as 'tipoCuentaCargo', -- 001 cuenta corriente , 002 cuenta ahorro L:3      
   (case TP.ban01moneda      
  when 'S' then '01' else '10' end) --       
  as 'monedaCuentaCargo' ,  -- 01 soles , 10 dolares  L:2      
   @nombreSolicitudLote+ Replicate(' ',12-LEN(@nombreSolicitudLote))    as 'nombreSolicitudLote' -- L:12      
         
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