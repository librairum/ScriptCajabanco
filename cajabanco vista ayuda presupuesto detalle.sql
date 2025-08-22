Create View V_PresupuestoConsulta
as
select Proveedor,Ruc,TipoDoc as 'Tipo Doc',NroDocumento as 'Nro Documento',          
    --  CAST(Soles As varchar(20)) as 'Soles',CAST(Dolares As varchar(20))as 'Dolares',       
      Soles  as 'Soles',Dolares as 'Dolares',       
     Diasatrazo as 'D Atrazo',Moneda as 'Mon',cast('' as bit) as IT,        
     FechaEmision as 'Fecha Emision',FechaVencimiento as 'Fecha Vencimiento',        
   --  AfectoDet  as 'A DET',Codigo,Tasa as 'Tasa DET'  ,        
   --PagoSolesDET as 'P Sol DET', PagoDolaresDET as 'P Dol DET',        
   --AfectoRET as 'A RET',TasaRet as 'Tasa RET', PagoSolesRET as 'P Sol RET', PagoDolaresRET as 'P Dol RET',        
   --PagoSoles as 'Pago Soles',PagoDolares as 'Pago Dolares',      
    Empresa ,OrigSoles,OrigDolares ,AfectoDet  as 'A DET',AfectoRET as 'A RET'      
   from V_Ban01PendientesPresupuesto    
   where rtrim(ltrim(Ruc))  + rtrim(ltrim(TipoDoc))  + rtrim(ltrim(NroDocumento))        
  not in (select distinct rtrim(ltrim(Ruc))  +
 rtrim(ltrim(TipoDoc))  + rtrim(ltrim(NroDoc)) from V_PrespuestoSeleccionados  )
 
 
 
 
 CREATE view V_Ban01PendientesPresupuesto  
 as                    
 Select D.CO05CODEMP as 'Empresa',                       
  isnull(p.ccm02nom,'') as 'Proveedor',                        
  isnull(p.ccm02ruc,'') as 'Ruc',                        
  D.CO05TIPDOC  as 'TipoDoc',                      
  D.CO05NRODOC as 'NroDocumento',  
  Convert(varchar(10),D.CO05FECHA,103) as 'FechaEmision',                        
  Convert(varchar(10),D.CO05FECVEN,103) as 'FechaVencimiento',  
  (DATEDIFF(DAY,CO05FECHA,CO05FECVEN))as 'Diasatrazo',                
                        
  D.CO05MONEDA as 'Moneda',  
  (case D.CO05MONEDA when 'S' then  D.co05import else '0.00' end) as 'Soles',   --D.Co05import  V.importeSol                     
  (case D.CO05MONEDA when 'D' then D.CO05IMPDOL  else '0.00' end) as 'Dolares',    --D.CO05IMPDOL    V.importeDol                 
 -- --AFECTO A DETRACCION EN MODO DE PRUEBA                       
 D.CO05AFECTODETRACCION as 'AfectoDET',                                          
  
                   
 --    --Nuevo 28/08/2014 AFECTO A RETENCION EN MODO DE PRUEBA                      
  D.Co05afectoret as 'AfectoRET',                           
    D.CO05IMPORT  as 'OrigSoles',                     
   D.CO05IMPDOL  as 'OrigDolares' 
                   
  From co05docu D  inner  join ccm02cta P  on  P.ccm02cod=d.CO05CODCTE                     
     and D.CO05CODEMP=P.ccm02emp                    
   left join Ban02PresupuestoPagoDetalle v on ---inner Join co05docu c (INDEX = co05docu_compago)  
   -- actualizacion de codigo 02/05/2025  
     D.CO05CODEMP = v.Ban02Empresa  
      And D.CO05CODCTE = v.Ban02Ruc   
      And D.CO05TIPDOC = v.Ban02Tipodoc  
      And D.CO05NRODOC = v.Ban02NroDoc                   
  Where P.ccm02tipana='02'
   
  and isnull(v.Ban02Ruc,'') = '' --  agregado el 02/05/2025  
  and D.CO05AA='2025'
  
  Go
  
  
  -----
  
   CREATE view V_PrespuestoSeleccionados
as          
  -- Docuemntos presupuestados y aprobados              
  --select Ban02Ruc as 'Ruc',Ban02Tipodoc as 'TipoDoc',        
  -- Ban02NroDoc as 'NroDoc' from Ban02DetPresupuestoPagos 
  -- where Ban02Estadoin ('ElabP')  --,'APROB'      
  -- and rtrim(ltrim(Ban02Ruc))  + rtrim(ltrim(Ban02Tipodoc))  + rtrim(ltrim(Ban02NroDoc)) not in 
		--					(select distinct rtrim(ltrim(Ban01Ruc))  + rtrim(ltrim(Ban01Tipodoc))  + rtrim(ltrim(Ban01NroDoc))        
		--				from Ban01DetAprobaciones where --Ban01Numero <>'00000'         
		--					Ban01Tipo in ('07','09') )        
  --union all                    
  select Ban02Ruc as 'Ruc',Ban02Tipodoc as 'TipoDoc',Ban02NroDoc as 'NroDoc' from Ban02PresupuestoPagoDetalle
  
  ---------------------------- creacion de vusta
  
CREATE View v_documentosPendientesPago              
As              
 -- Insertar Provision              
 Select CO05CODEMP,CO05CODCTE,CO05TIPDOC,CO05NRODOC,       
 Sum(Isnull((case CO05TIPDOC when '07' then CO05IMPORT *-1 else CO05IMPORT end ),0)) as importeSol,              
 Sum(Isnull((case CO05TIPDOC when '07' then Co05IMPDOL *-1 else Co05IMPDOL end ),0)) as importeDol              
 from co05docu               
 --Where  CO05ESTADO='3'               
 Group by CO05CODEMP,CO05CODCTE,CO05TIPDOC,CO05NRODOC               
               
 Union all              
 -- Insertar los pagos al proveedor              
 Select Ban01Empresa,Ban01Ruc,Ban01Tipodoc,Ban01NroDoc,              
     
 (Sum(Isnull(Ban01ImportePagarSol,0)) + Sum(isnull(Ban02SolesVale,0)))* (Case When Ban01Tipodoc='07' then -1 else -1 end) as importeSol,              
 (Sum(Isnull(Ban01ImportePagarDol,0)) + SUM(isnull(Ban02DolaresVale,0)))*(Case When Ban01Tipodoc='07' then -1 else -1 end) as importeDol              
     
 from Ban01PagosDocuxCompagos Inner Join Ban02DetPresupuestoPagos On           
     Ban02Empresa = Ban01Empresa          
 And Ban02Ruc=Ban01Ruc           
 And Ban02Tipodoc = Ban01Tipodoc          
 And Ban02NroDoc  = Ban01NroDoc          
 And Ban02Codigo = Ban01Codigo          
  Group by Ban01Empresa,Ban01Ruc,Ban01Tipodoc,Ban01NroDoc              
 --==== 06/04/2015        
  Union all              
 -- Insertar los pagos de Liquidacion             
 Select Ban01Empresa,Ban01RucLiq,Ban01TipoDocLiq,Ban01NroDocLiq,              
 Sum(Isnull(Ban01SolesLiq,0))*-1 as importeSol,              
 Sum(Isnull(Ban01DolaresLiq,0))*-1 as importeDol              
 from Ban01PagosDetLiquid Inner Join co05docu On           
     Ban01Empresa = Ban01Empresa          
 And CO05CODCTE=Ban01Ruc           
 And CO05TIPDOC = Ban01Tipodoc          
 And CO05NRODOC  = Ban01NroDoc          
 --And Ban02Codigo = Ban01Codigo          
  Group by Ban01Empresa,Ban01RucLiq,Ban01TipoDocLiq,Ban01NroDocLiq         
 --====           
             
 -- Insertar los pagos por detraccion              
 Union all              
 Select CO26CODEMP,CO26RUC,CO26TIPDOC,CO26NRODOC,              
 Sum(Isnull(CO26IMPORTEDETRA,0))*-1 as importeSol,               
 Sum(Isnull(CO26IMPORTEDETRADOL,0))*-1 as importeDol              
 from CO26PAGODETRACCION   Inner Join Ban02DetPresupuestoPagos On             
 CO26RUC = Ban01Ruc And CO26TIPDOC=Ban01Tipodoc And CO26NRODOC=Ban01NroDoc            
 Where isnull(CO26CONST_CONSDETRA,'')<>'' Group by CO26CODEMP,CO26RUC,CO26TIPDOC,CO26NRODOC              
               
 Union all              
 -- Insertar los pagos por Retencion              
 Select rete.Ban01Empresa,rete.Ban01Ruc,rete.Ban01Tipo,rete.Ban01NroDoc,              
 Sum(Isnull(rete.Ban01Retenido,0))*-1 as importeSol,              
 Sum(Isnull(rete.Ban01RetenidoDolares,0))*-1 as importeDol              
 from Ban01RetencionDet rete Inner Join Ban01PagosDocuxCompagos pago On            
 rete.Ban01Ruc = pago.Ban01Ruc And rete.Ban01Tipo=pago.Ban01Tipodoc And rete.Ban01NroDoc=pago.Ban01NroDoc and             
 rete.Ban01Codigo= pago.Ban01Codigo  
             
  Group by rete.Ban01Empresa,rete.Ban01Ruc,rete.Ban01Tipo,rete.Ban01NroDoc 