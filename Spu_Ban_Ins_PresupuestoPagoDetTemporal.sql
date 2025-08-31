ALTER procedure Spu_Ban_Ins_PresupuestoPagoDetTemporal            
@Empresa char(2),            
@NumeroPresupuesto varchar(5),            
@TipoAplicacion char(2),           
@FechaPresupuesto varchar(10),            
@BcoLiquidacion char(2),           
@xmlDetalle xml,            
@flag int output,            
@mensaje varchar(200) output            
as            
Begin            
Begin transaction            
        
      
Declare @tmp_rango TABLE (ruc char(11),             
codigoTipDoc varchar(2),             
numeroDocumento varchar(20),               
monedaOriginal char(1),             
soles varchar(10),              
dolares varchar(10),             
fechaEmision varchar(10),              
fechavencimiento varchar(10) )               
                 
                      
If @xmlDetalle.exist('//tbl') = 1                     
 Begin                          
  DECLARE @HANDLE INT                          
  EXEC SP_XML_PREPAREDOCUMENT @HANDLE OUTPUT, @xmlDetalle                          
  INSERT INTO  @tmp_rango                          
  SELECT ruc, codigoTipDoc , numeroDocumento, monedaOriginal ,                
  soles , dolares, fechaEmision  , fechaVencimiento              
  FROM OPENXML(@HANDLE,'/DataSet/tbl',2)                          
  WITH( ruc char(11), 
  codigoTipDoc varchar(2), 
  numeroDocumento varchar(20),               
  monedaOriginal char(1), 
  soles varchar(10),                
  dolares varchar(10), 
  fechaEmision varchar(10),              
  fechaVencimiento varchar(10))                          
 End            
                 
    declare @tblDetalletmp as table(  
    ban02Empresa char(2),  
    ban01Nunero char(5),            
    ban02Ruc varchar(11),  
    ban02TipDoc char(2),  
    ban02NroDoc varchar(50),
    importeSoles decimal(10,2),
    importeDolares decimal(10,2)

 )              
          
           
 declare @TC numeric(8,3)=(select VenBan from TiCambio              
   where convert(varchar(10),Fecha,103)=@fechapresupuesto)                  
         
   insert into @tblDetalletmp     (ban02Empresa, ban01Nunero,   ban02Ruc, ban02TipDoc, ban02NroDoc, importeSoles, importeDolares )   
   select @Empresa, @numeroPresupuesto, 
   tbl.ruc,       
   tbl.codigoTipDoc ,
   numeroDocumento,
   tbl.soles  , 
   tbl.dolares     
   from @tmp_rango tbl        
      
     
----------------------------------------------------------------------      
   select tmp.ban02Empresa, ban01Nunero,   ban02Ruc, ban02TipDoc, ban02NroDoc,  tmp.importeSoles, tmp.importeDolares,          
   (case d.CO05AFECTODETRACCION       
   when 'S' then  'si' else 'no' end) as AfectaDetraccion,            
            
(CASe d.CO05AFECTODETRACCION when 'S' THEN  d.CO05DETRATIPOPERACION ELSE '' END) as tipoDetraccion,            
(CASE D.CO05AFECTODETRACCION WHEN 'S' THEN  d.CO05DETRAPORCENTAJE ELSE 0 END) as  TasaDetraccion,    
(case d.CO05AFECTODETRACCION when 'S'            
 then CO05DETRAIMPORTE else 0 end)as ImporteDetraccionSoles,            
 (case d.CO05AFECTODETRACCION when 'S'   
 then  CO05DETRAIMPORTE_EQUI else 0 end) as ImporteDetraccionDolares,            
            
(case d.Co05afectoret when 'S' then 'si' else 'no' end) as AfectaRetencion,            
 (CASE D.CO05AFECTORET WHEN 'S' THEN 3 ELSE 0 END)  as TasaRetencion,            
 (case d.Co05afectoret when 'S'             
 then (             
  case d.CO05MONEDA when 'S' then 0             
  else 0 end)            
  else 0 end) as ImporteRetencionSoles,            
  0 as ImporteRetencionDolares,            
  0 as TasaPercepcion,            
  0 as ImportePercepcionSoles, 
  0 as ImportePercepcionDolares,
  Co05afectoret, co05moneda,       
  CO05CODCTE       
  into #tblPresupuestoCalculo            
            
 from @tblDetalletmp tmp inner join     co05docu D on                                             
       tmp.Ban02Empresa = D.CO05CODEMP                                                                                 
        and tmp.ban02TipDoc=D.CO05TIPDOC                                             
        and tmp.Ban02NroDoc = D.CO05NRODOC                                      
        and tmp.Ban02Ruc = D.CO05CODCTE          
   -----------------------------------------------------------------------------------------------------------      
        Update #tblPresupuestoCalculo                            
 Set Co05afectoret='S'                            
 Where                            
 ltrim(rtrim(CO05CODCTE)) + ltrim(rtrim(co05moneda))in                             
      (Select Distinct ltrim(rtrim(CO05CODCTE)) + ltrim(rtrim(co05moneda)) from #tblPresupuestoCalculo Where                             
        Co05afectoret='S')               
   
       
      
-------------------------------------------------------------------------------      
                     
             
   declare @numero int               
    select @numero =isnull(max(cast(Ban02Codigo as int)),0)           
    from Ban02PresupuestoPagoDetalle              
              --sp_help Ban02PresupuestoPagoDetalle
    insert into  Ban02PresupuestoPagoDetalle
	(
	Ban02Empresa,
    Ban02Ruc,
    Ban02Tipodoc,
    Ban02NroDoc,
    Ban02Codigo,
    Ban02Numero,
    --Ban02Estado,
    Ban02TipoDetraccion,
    Ban02TasaDetraccion,
    Ban02ImporteDetraccionSoles,
    Ban02ImporteDetraccionDolares,
    Ban02TasaRetencion,
    Ban02ImporteRetencionSoles,
    Ban02ImporteRetencionDolares,
    Ban02TasaPercepcion,
    Ban02ImportePercepcionSoles,
    Ban02ImportePercepcionDolares,
    Ban02NetoSoles,
    Ban02NetoDolares
	)                   
    select     
	ban02Empresa,
	ban02Ruc,
	ban02TipDoc,
	ban02NroDoc,            
    dbo.ObtenerCorrelativoFormateado(row_number() over (order by ban02NroDoc desc) +@numero)  as ban02codigo,            
   ban01Nunero,
      
    tipoDetraccion,            
    TasaDetraccion,
	ImporteDetraccionSoles,
	ImporteDetraccionDolares, 
	           
    TasaRetencion ,            
    ImporteRetencionSoles,
	ImporteRetencionDolares,            
    ---------------------------------            
    TasaPercepcion,
	ImportePercepcionSoles,  
	ImportePercepcionDolares,
	
     importeSoles - (ImporteDetraccionSoles+ImporteDetraccionSoles+ ImporteRetencionSoles), 
     importeDolares  - (ImporteDetraccionDolares+ImporteRetencionDolares+ImportePercepcionDolares)
     
	 --,      
     --fechaEmision, fechaVencimiento                    
      from #tblPresupuestoCalculo tbl                  
       left  join ccm02cta P  on                                      
  tbl.Ban02Ruc= P.ccm02cod           
  and tbl.Ban02Empresa= p.ccm02emp And P.ccm02tipana='02'                  
         
  if @@ERROR  <> 0             
  Begin             
	  set @mensaje = 'Error al insertar detalle'              
	  goto ManejaError             
  end                 
  set @mensaje = 'Insercion exitosa' set @flag  = 1           
  commit transaction            
  return 1           
  ManejaError:           
  set @flag = -1           
  rollback transaction           
  return -1             
  End   
  