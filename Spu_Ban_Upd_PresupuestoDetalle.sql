ALTER Procedure Spu_Ban_Upd_PresupuestoDetalle              
@Ban02Empresa char(2),              
@Ban02Numero varchar(5),              
@Ban02Codigo varchar(5),              
@Ban02PagoSoles decimal(12,3),              
@Ban02PagoDolares decimal(12,3),              
              
@Ban02TasaDetraccion decimal(5,2),              
@Ban02ImporteDetraccionSoles decimal(12,3),              
@Ban02ImporteDetraccionDolares decimal(12,3),              
               
@Ban02TasaRetencion decimal(5,2),              
@Ban02ImporteRetencionSoles decimal(12,3),              
@Ban02ImporteRetencionDolares decimal(12,3),              
              
@Ban02TasaPercepcion decimal(5,2),              
@Ban02ImportePercepcionSoles decimal(12,3),              
@Ban02ImportePercepcionDolares decimal(12,3),         
--@Ban02NetoSoles decimal(12,3),    
--@Ban02NetoDolares decimal(12,3),    
@flag int output,              
@mensaje varchar(200) output              
as              
Begin              
begin transaction              
update Ban02PresupuestoPagoDetalle               
set               
Ban02PagoSoles = @Ban02PagoSoles,              
Ban02PagoDolares = @Ban02PagoDolares,              
Ban02TasaDetraccion = @Ban02TasaDetraccion,              
Ban02ImporteDetraccionSoles = @Ban02ImporteDetraccionSoles,              
Ban02ImporteDetraccionDolares = @Ban02ImporteDetraccionDolares,              
Ban02TasaRetencion = @Ban02TasaRetencion,              
            
Ban02ImporteRetencionSoles = @Ban02ImporteRetencionSoles,              
Ban02ImporteRetencionDolares = @Ban02ImporteRetencionDolares,              
Ban02TasaPercepcion = @Ban02TasaPercepcion,              
Ban02ImportePercepcionSoles = @Ban02ImportePercepcionSoles,              
Ban02ImportePercepcionDolares  = @Ban02ImportePercepcionDolares              
          
-- actualizo el neto pago          
--,Ban02NetoSoles  = @Ban02NetoSoles    
--, Ban02NetoDolares = @Ban02NetoDolares          
          
where Ban02Empresa = @Ban02Empresa             
and Ban02Numero = @Ban02Numero              
and ban02codigo = @Ban02Codigo              
--- actualizo el total de calculo neto        
--declare @netosoles as decimal(12,3)        
--declare @netodolares as decimal(12,3)        
        
--update        
--Ban02NetoSoles        
--Ban02NetoDolares        
        
if @@error <> 0               
begin              
 set @mensaje = 'Error al actualizar'              
 Goto ManejaError              
End              
              
              
set @mensaje= 'Actualizacion exitosa'              
set @flag = 1              
commit transaction              
return 1              
              
ManejaError:              
set @flag = -1              
rollback transaction              
return  -1              
              
End   
  