CREATE Procedure Spu_Ban_Trae_DetallePresupuestoTemporal    
@Empresa char(2),              
@numeroPresupuesto varchar(5),              
@tasaRetencion decimal(10,2) = 3              
              
as              
Begin              
If  @numeroPresupuesto='00001'   
begin        
   select TOP 100 ROW_NUMBER() over(order by ban02codigo asc)  as Item, Ban02Codigo , Ban02Ruc,     
   dbo.ObtenerNombreCta(@Empresa,dpp.Ban02Ruc)  as RazonSocial,        
     isnull(tipodoc.FAC01DESC,'') as NombreTipoDocumento,   dpp.Ban02NroDoc, dpp.Ban02Moneda,         
     (case dpp.Ban02Moneda when 'S' then 'SOLES' ELSE 'DOLARES' END) AS NOMBREMONEDA,        
     --dpp.Ban02Soles, dpp.Ban02Dolares,         
     dpp.Ban02PagoSoles, dpp.Ban02PagoDolares,  dpp.Ban02TipoDetraccion, dpp.ban02Tasadetraccion        
     ,     
     (case dpp.Ban02Moneda  when 'S'     
     then  dpp.Ban02ImporteDetraccionSoles     
   else dpp.[Ban02ImporteDetraccionDolares] end) as 'ImporteDetraccion',    
     dpp.Ban02ImporteDetraccionSoles, dpp.[Ban02ImporteDetraccionDolares],        
             
            
     dpp.[Ban02TasaRetencion],  dpp.[Ban02ImporteRetencionSoles],         
     dpp.[Ban02ImporteRetencionDolares],        
     dpp.[Ban02TasaPercepcion],        
         
     dpp.[Ban02ImportePercepcionSoles],        
     dpp.[Ban02ImportePercepcionDolares]
	 --,        
     --dpp.[Ban02NetoSoles],        
     --dpp.[Ban02NetoDolares]  ,      
     --dpp.Ban02FechaEmision,      
     --dpp.Ban02FechaVencimiento  
	 --, dpp.Ban02TipoCambio    
        
   From Ban02PresupuestoPagoDetalle dpp        
   left join FAC01_TIPDOC tipodoc        
   on dpp.Ban02Empresa = tipodoc.FAC01CODEMP        
   and dpp.Ban02Tipodoc = tipodoc.FAC01COD        
           
   where Ban02Empresa = @Empresa         
   and Ban02Numero = @numeroPresupuesto             
  END  
  eLSE  
  bEGIN  
     select ROW_NUMBER() over(order by ban02codigo asc)  as Item, Ban02Codigo , Ban02Ruc,     
   dbo.ObtenerNombreCta(@Empresa,dpp.Ban02Ruc)  as RazonSocial,        
     isnull(tipodoc.FAC01DESC,'') as NombreTipoDocumento,   dpp.Ban02NroDoc, dpp.Ban02Moneda,         
     (case dpp.Ban02Moneda when 'S' then 'SOLES' ELSE 'DOLARES' END) AS NOMBREMONEDA,        
     --dpp.Ban02Soles, dpp.Ban02Dolares,         
     dpp.Ban02PagoSoles, dpp.Ban02PagoDolares,  dpp.Ban02TipoDetraccion, dpp.ban02Tasadetraccion        
     ,     
     (case dpp.Ban02Moneda  when 'S'     
     then  dpp.Ban02ImporteDetraccionSoles     
   else dpp.[Ban02ImporteDetraccionDolares] end) as 'ImporteDetraccion',    
     dpp.Ban02ImporteDetraccionSoles, dpp.[Ban02ImporteDetraccionDolares],        
             
            
     dpp.[Ban02TasaRetencion],  dpp.[Ban02ImporteRetencionSoles],         
     dpp.[Ban02ImporteRetencionDolares],        
     dpp.[Ban02TasaPercepcion],        
         
     dpp.[Ban02ImportePercepcionSoles],        
     dpp.[Ban02ImportePercepcionDolares]
	 --,        
     --dpp.[Ban02NetoSoles],        
     --dpp.[Ban02NetoDolares]  ,      
     --dpp.Ban02FechaEmision,      
     --dpp.Ban02FechaVencimiento  
	 --, dpp.Ban02TipoCambio    
        
   From Ban02PresupuestoPagoDetalle dpp        
   left join FAC01_TIPDOC tipodoc        
   on dpp.Ban02Empresa = tipodoc.FAC01CODEMP        
   and dpp.Ban02Tipodoc = tipodoc.FAC01COD        
           
   where Ban02Empresa = @Empresa         
   and Ban02Numero = @numeroPresupuesto    
  eND  
    
End