--select * from sys.objects where type = 'P'
--order by modify_date desc

Create procedure Spu_Ban_Del_PresupuestoDetraccionIndividual  
@empresa char(2),  
@nropresupuesto varchar(5),  
@flag int output,  
@mensaje varchar(100) output  
as  
Begin  
  
begin transaction  
  
delete from Ban01PresupuestoPago  
where Ban01Empresa = @empresa   
and Ban01Numero = @nropresupuesto  
if @@ERROR<> 0   
Begin  
Goto ManejaError  
End  
  
delete from Ban02PresupuestoPagoDetalle  
where Ban02Empresa = @empresa  
and Ban02Numero = @nropresupuesto  
  
if @@ERROR<> 0   
Begin  
Goto ManejaError  
End  
  
  
set @flag =1   
set @mensaje = 'Eliminacion exitosa de presupuesto'  
commit transaction  
  
return 1  
ManejaError:  
set @flag = -1  
set @mensaje = 'Error al elimianr presupuesto desde detraccion individual'  
rollback transaction  
  
return -1  
End  
  Go
CREATE Procedure Spu_Ban_Trae_DetraccionIndividualCab      
@Ban01Empresa char(2),      
@Ban01Anio  char(4),      
@Ban01Mes  char(2),      
@Ban01motivopagoCod char(2)      
      
As      
Select pc.Ban01Numero,pc.Ban01Empresa,pc.Ban01Anio,pc.Ban01Mes,pc.Ban01Descripcion,    
medio.Ban01Descripcion as nombreMedioPago,    
convert(varchar(10),pc.Ban01Fecha, 103) as Ban01Fecha ,      
pd.Ban02Ruc,pd.Ban02Tipodoc,pd.Ban02NroDoc,  
(case CO05MONEDA when 'S' then 'SOLES' else 'DOLARES' end) as CO05MONEDA,    
convert(varchar(10),CO05FECHA,103) as CO05FECHA,    
convert(varchar(10),CO05FECVEN, 103) as CO05FECVEN ,      
CO05IMPORT As 'ImporteBrutoSoles', CO05IMPDOL as 'ImporteBrutoDolares',      
Ban02TipoDetraccion,Ban02TasaDetraccion,Ban02PagoSoles as 'PagoDetracionSoles',    
Ban02PagoDolares as 'PagoDetracionDolares' ,    
prov.ccm02nom as 'nombreproveedor'  ,  
(case Ban01Estado when   '01' then 'GENERADO'   
  when '02' then 'PAGADO' end) as estadopresupuesto,  
  convert(varchar(10),pc.Ban01FechaEjecucionPago,103) as fechaejecucionpago,  
  Ban01NroOperacion as nrooperacion  
  
From ban02presupuestopagodetalle pd  Inner join   Ban01PresupuestoPago pc      
on pc.Ban01Empresa = pd.Ban02Empresa        
and pc.Ban01Numero = pd.Ban02Numero  Inner Join CO05DOCU docu On          
pd.Ban02Empresa = docu.CO05CODEMP and           
pd.Ban02Ruc = docu.CO05CODCTE and           
pd.Ban02Tipodoc = docu.CO05TIPDOC and           
pd.Ban02NroDoc = docu.CO05NRODOC          
left join Ban01TipoPago medio     
on medio.Ban01Empresa = pc.Ban01Empresa    
and medio.Ban01IdTipoPago =  pc.Ban01MedioPago    
left join ccm02cta prov    
    
on prov.ccm02tipana = '02'    
and prov.ccm02emp = pc.Ban01Empresa    
and prov.ccm02cod = pd.Ban02Ruc    
    
  
inner join Ban01Estado E       
 on pc.Ban01Empresa=e.Ban01Empresa        
 and pc.Ban01Estado = e.Ban01Codigo   
Where      
    pc.Ban01Empresa=@Ban01Empresa      
And pc.Ban01Anio=@Ban01Anio      
And pc.Ban01Mes=@Ban01Mes      
And pc.Ban01motivopagoCod=@Ban01motivopagoCod 