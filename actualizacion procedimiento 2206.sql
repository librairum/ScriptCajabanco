use traver
go
select * from sys.objects order by modify_date desc


create procedure Spu_Ban_Del_PrepuestoDetraccion  
@Ban01Empresa char(2),   
@Ban01Numero  varchar(5),  
@flag int output,  
@mensaje varchar(200) output  
AS  
Begin transaction  
--  
Delete from Ban01PresupuestoPago where Ban01Empresa='01' and Ban01Numero='00026'  
if @@ERROR <> 0   
Begin  
set @mensaje = 'Error al eliminar presupuesto'  
Goto ManejaError  
end  
--  
Delete from Ban02PresupuestoPagoDetalle where Ban02Empresa='01' and Ban02Numero='00026'  
if @@ERROR <>  0  
Begin  
set @mensaje = 'Error al eliminar presupuesto'  
Goto ManejaError  
end  
set @flag = 1  
Commit transaction  
return 1   
  
ManejaError:  
Rollback transaction  
return -1  
Go
alter Procedure Spu_Ban_Ins_PresupuestoDetraMasiva           
@Ban01Empresa varchar(2),                          
@Ban01Anio varchar(4),                            
@Ban01Mes varchar(2),                            
@Ban01Descripcion varchar(400),        
                    
@Ban01Fecha varchar(10),    -- se asignara la fecha desde el web frontend del metodo actualiza comprobante                      
@Ban01Estado varchar(2),      
@Ban01Usuario varchar(15),                            
@Ban01Pc varchar(20
),                            
@Ban01FechaRegistro varchar(10),                       
@Ban01MedioPago     char(2),              
@DetraccionLote  varchar(6),          
@Ban01motivopagoCod char(2), -- el 03 es pagoi detraccion Masivo        
-- Agregar los campos del pago           
--@fechapago VARCHAR(10),      -- formulario web  frontend parametro del metod actualiza comprobante      
@numerooperacion VARCHAR(10),      --formulario web frontend del metod actualiza comprobante      
@enlacepago VARCHAR(MAX),      --formulario web  frontend del metod actualiza comprobante      
@nombreArchivo VARCHAR(MAX),      -- formulario web frontend del metod actualiza comprobante      
@contenidoArchivo VARBINARY(MAX),      --formulario web frotend del metod actualiza comprobante      
@flagOperacion CHAR(1),      --formulario web frontend del metodo actualiza comprobante      
          
---------------------                            
@flag int output,            
@mensaje varchar(200) output,            
@codigoGenerado varchar(5) output            
--           
as                            
Begin transaction      
-- Genera correlativo del presipuesto          
declare @ultimoCodigo     varchar(5)          
select @ultimoCodigo = dbo.ObtenerCorrelativoFormateado(ISNULL(mAX(RIGHT(Ban01Numero,4)),0)+1) from Ban01PresupuestoPago                
Select @ultimoCodigo          
          
          
-- Insertar Cabecera                  
Insert into Ban01PresupuestoPago(Ban01Numero,Ban01Empresa,Ban01Anio,Ban01Mes,
      
Ban01motivopagoCod,Ban01Descripcion,Ban01Fecha,Ban01Estado,Ban01Usuario,Ban01Pc,Ban01FechaRegistro,          
Ban01MedioPago, Ban01DetraMasivaLote)          
 values (@ultimoCodigo, @Ban01Empresa, @Ban01Anio,@Ban01Mes, @Ban01motivopagoCod,        

 @Ban01Descripcion, @Ban01Fecha, @Ban01Estado, @Ban01Usuario, @Ban01Pc,               
 @Ban01Fecha, @Ban01MedioPago, @DetraccionLote )                 
              
    if @@ERROR <> 0      
    Begin      
  set @mensaje = 'Error al registrar cabecera
 detraccion'      
  Goto ManejaError      
    end      
          
-- Insertar Detalle           
Insert Into Ban02PresupuestoPagoDetalle(Ban02Empresa,Ban02Numero,Ban02Codigo,Ban02Ruc,Ban02Tipodoc,Ban02NroDoc          
,Ban02PagoSoles,Ban02PagoDolares  
        
,Ban02TipoDetraccion          
,Ban02TasaDetraccion          
,Ban02ImporteDetraccionSoles,Ban02ImporteDetraccionDolares,          
Ban02TasaRetencion,Ban02ImporteRetencionSoles,Ban02ImporteRetencionDolares,          
Ban02TasaPercepcion,Ban02ImportePercepcionSoles,Ban02ImportePercepcionDolares,           
Ban02NetoSoles,Ban02NetoDolares          
)          
          
          
Select @Ban01Empresa as 'empresa',@ultimoCodigo,      
RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT CO26NUMLOTE)) AS VARCHAR(5)), 5) as 'Correlativo',          
CO26RUC,CO26TIPDOC,CO26NRODOC,          
Convert(decimal(18,2),CO26IMPORTEDETRA),Convert(decimal(9,2),CO26IMPORTEDETRADOL),          
''as 'Detra_Tipo',          
0 as 'Detra_porcentaje',          
0
 as 'Detra_ImpSoles',          
0 as 'Detra_ImpDolares',          
--          
0 as 'RetencionTasa',          
0 as 'RetencionMontoSoles',          
0 as 'RetencionMontoDolares',          
0 as 'PercepcionTasa',          
0 as 'PercepcionSoles',         
 
0 as 'PercepcionDolares',          
Convert(decimal(9,2),CO26IMPORTEDETRA),          
Convert(decimal(9,2),CO26IMPORTEDETRADOL)          
 From CO26PAGODETRACCION detra Inner Join CO05DOCU docu On          
detra.CO26CODEMP = docu.CO05CODEMP and        

detra.CO26RUC = docu.CO05CODCTE and           
detra.CO26TIPDOC = docu.CO05TIPDOC and           
detra.CO26NRODOC = docu.CO05NRODOC          
where           
Detra.CO26CODEMP=@Ban01Empresa and detra.CO26NUMLOTE=@DetraccionLote          
      
if @@ERROR  <> 0       
begin      
 set @mensaje = 'Error al registrar detalle detraccion'      
 Goto ManejaError      
end          
--Select *  from CO26PAGODETRACCION where CO26CODEMP='01' and CO26NUMLOTE='200710'          
      
declare @flagComprobante as 
int       
declare @mensajeComprobante as varchar(100)      
exec Spu_Ban_Upd_ComprobantePago @Ban01Empresa,@Ban01Anio,       
@Ban01Mes, @ultimoCodigo, @Ban01Fecha, @numerooperacion, @enlacepago,      
@nombreArchivo,@contenidoArchivo,@flagOperacion, @flagComprobante out , @mensajeComprobante out      
      
      
set @flag = 1      
set @mensaje = 'El Pago detraccion se registro exitosamente'      
commit transaction      
return 1      
ManejaError:      
set @flag = -1      
set @mensaje = 'Error al
 registrar pago de detraccion'      
rollback transaction
return -1

alter Procedure Spu_Ban_Trae_DetraccionMasivaCab    
@empresa char(2),    
@anio  char(4),    
@mes  char(2),    
@motivopago char(2) -- 03 detraccion masiva    
As    
Begin  
Select     
CO26CODEMP as 'EmpresaCod',    
CO26AA as 'Anio',    
CO26MES as 'Mes',    
CO26NUMLOTE as 'LoteDetraccionNro',    
'' as 'PresupuestoCod',    
Sum(CO26IMPORTFACT) as 'FacturaImporteSol',     
sum(CO26IMPORTEDETRA) as 'DetraccionImporteSol'  ,  
'' as 'nombreMedioPago' ,  
'' as 'bancoMedioPago' ,  
'' as 'motivo' ,'' as 'fecha',  
'' as 'bancoCodMedioPago'  
From CO26PAGODETRACCION detra Inner Join CO05DOCU docu On        
detra.CO26CODEMP = docu.CO05CODEMP and         
detra.CO26RUC = docu.CO05CODCTE and         
detra.CO26TIPDOC = docu.CO05TIPDOC and         
detra.CO26NRODOC = docu.CO05NRODOC        
where         
Detra.CO26CODEMP=@empresa    
And Detra.CO26AA=@anio    
And Detra.CO26MES=@mes    
And CO26NUMLOTE <>'00000'    
And CO26NUMLOTE not in (Select distinct Ban01DetraMasivaLote from Ban01PresupuestoPago 
where Ban01Empresa=@empresa and Ban01motivopagoCod='03') -- Detraccion Masiva)
Group by CO26CODEMP,CO26AA,CO26MES,CO26NUMLOTE    
Union All    
Select     
Ban01Empresa as 'EmpresaCod',    
Ban01Anio as 'Anio',     
Ban01Mes as 'Mes',    
--'' as 'LoteDetraccionNro',    
Ban01DetraMasivaLote as 'LoteDetraccionNro',    
Ban01Numero as 'PresupuestoCod',    
ImpBrutoSoles as 'FacturaImporteSol',     
ImpDetraccionSoles as 'DetraccionImporteSol'  ,  
nombreMedioPago as 'nombreMedioPago',  
nombreBanco as 'bancoMedioPago',  
motivo as 'motivo',  
convert(varchar(10),FechaPresupuesto, 103) as 'fecha',  
bancoCodMedioPago as 'bancoCodMedioPago'  
From V_PresupuestoTotales     
Where Ban01Empresa=@empresa and Ban01Anio=@anio and Ban01Mes=@mes and Ban01motivopagoCod=@motivopago -- Detracciones masivas    
End  
Go
alter procedure Spu_Ban_Trae_DocPendiente_Detra    
@empresa char(2),                  
@ruc varchar(100) ,            
@numeroDocumento varchar(100)            
  as              
               
  Begin              
  if @ruc = ''  and @numeroDocumento = ''            
  Begin                                
     select       
     dcp.Ruc + dcp.[NroDocumento] as Clave,          
     dcp.Ruc,               
     dcp.Proveedor as RazonSocial,                
     dcp.[TipoDoc] as CodigoTipoDoc,       
       
     isnull(td.ccb02des,'') as NombreTipoDoc,              
   dcp.[NroDocumento] as NumeroDocumento,              
   dcp.Moneda as MonedaOriginal,              
              
   dcp.OrigSoles as OrigSoles,              
   dcp.OrigDolares as OrigDolares,              
   dcp.[FechaEmision] as FechaEmision,              
   (case isnull(dcp.[AfectoDet],'N')  when 'S' then 'SI' else 'NO' end) as AfectoDetraccion,    
   DetraTipoServicio,DetraPorcentaje,DetraImpSol,DetraImpDol    
    
          

     from V_PresupuestoConsulta_detra dcp        
     left join ccb02tipd td              
     on  dcp.Empresa = td.ccb02emp      
     and dcp.[TipoDoc] = td.ccb02cod      
    where Empresa=@empresa                 
                   
    order by FechaEmision desc                    
   End           
           
   Else  if @numeroDocumento <> '' and @ruc <> ''            
   Begin             
                               
     select       
     dcp.Ruc + dcp.[NroDocumento] as Clave,          

     dcp.Ruc,               
     dcp.Proveedor as RazonSocial,                
     dcp.[TipoDoc] as CodigoTipoDoc,              
     isnull(td.ccb02des,'') as NombreTipoDoc,  
   dcp.[NroDocumento] as NumeroDocumento,              
   dcp.Moneda as MonedaOriginal,              
              
   dcp.OrigSoles as OrigSoles,              
   dcp.OrigDolares as OrigDolares,              
   dcp.[FechaEmision] as FechaEmision,              
   (case isnull(dcp.[AfectoDet],'N')  when 'S' then 'SI' else 'NO
' end) as AfectoDetraccion,    
   DetraTipoServicio,DetraPorcentaje,DetraImpSol,DetraImpDol    
            
     from V_PresupuestoConsulta_detra dcp                      
     left join ccb02tipd td              
     on  dcp.Empresa = td.ccb02emp     
 
     and dcp.[TipoDoc] = td.ccb02cod      
                 
    where Empresa=@empresa               
    and dcp.Ruc = @ruc   and dcp.[NroDocumento] like '%'+ @numeroDocumento + '%'            
     order by dcp.FechaEmision desc            
         
   
   End              
   else if (@numeroDocumento <> '' and  @ruc = '') or (@numeroDocumento = '' and @ruc <> '')            
   Begin            
                           
     select         
         dcp.Ruc + dcp.[NroDocumento] as Clave,        
  
     dcp.Ruc,               
     dcp.Proveedor as RazonSocial,                
     dcp.[TipoDoc] as CodigoTipoDoc,              
     isnull(td.ccb02des,'') as NombreTipoDoc,  
   dcp.[NroDocumento] as NumeroDocumento,              
   dcp.Moneda as MonedaOriginal,              
              
   dcp.OrigSoles as OrigSoles,              
   dcp.OrigDolares as OrigDolares,              
   dcp.[FechaEmision] as FechaEmision,              
   (case isnull(dcp.[AfectoDet],'N')  when 'S' then 'SI' else 'NO' end) as AfectoDetraccion,    
   DetraTipoServicio,DetraPorcentaje,DetraImpSol,DetraImpDol    
        
     from V_PresupuestoConsulta_detra dcp                      
          left join ccb02tipd td              
     on  dcp.Empresa = td.ccb02emp  
    
     and dcp.[TipoDoc] = td.ccb02cod      
    where Empresa=@empresa            
    and (@numeroDocumento =  '' or dcp.[NroDocumento] like '%'+ @numeroDocumento+ '%')             
    and (@ruc = '' or dcp.[Ruc] = @ruc)             
    order by dcp.FechaEmision desc            
   End
   End