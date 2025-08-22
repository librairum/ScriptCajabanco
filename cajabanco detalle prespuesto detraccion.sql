CREATE view V_Ban01PendientesPresupuesto                    
 as                    
 Select D.CO05CODEMP as 'Empresa',                       
  isnull(p.ccm02nom,'') as 'Proveedor',                        
  isnull(p.ccm02ruc,'') as 'Ruc',                        
  D.CO05TIPDOC  as 'TipoDoc',                      
  D.CO05NRODOC as 'NroDocumento',Convert(varchar(10),D.CO05FECHA,103) as 'FechaEmision',                        
  Convert(varchar(10),D.CO05FECVEN,103) as 'FechaVencimiento',(DATEDIFF(DAY,CO05FECHA,CO05FECVEN))as 'Diasatrazo',                
                        
  D.CO05MONEDA as 'Moneda',(case D.CO05MONEDA when 'S' then  V.importeSol else '0.00' end) as 'Soles',   --D.Co05import  V.importeSol                     
  (case D.CO05MONEDA when 'D' then V.importeDol  else '0.00' end) as 'Dolares',    --D.CO05IMPDOL    V.importeDol                 
 -- --AFECTO A DETRACCION EN MODO DE PRUEBA                       
 D.CO05AFECTODETRACCION as 'AfectoDET',                                          
                     
 --    --Nuevo 28/08/2014 AFECTO A RETENCION EN MODO DE PRUEBA                      
  D.Co05afectoret as 'AfectoRET',                           
    V.importeSol  as 'OrigSoles',                     
   V.importeDol  as 'OrigDolares'                    
  From co05docu D (INDEX = co05docu_compago) inner  join ccm02cta P  on  P.ccm02cod=d.CO05CODCTE                     
     and D.CO05CODEMP=P.ccm02emp                    
   inner join v_doc2 v on ---inner Join co05docu c (INDEX = co05docu_compago)                     
     D.CO05CODEMP = v.CO05CODEMP                     
      And D.CO05CODCTE = v.CO05CODCTE                      
      And D.CO05TIPDOC = v.CO05TIPDOC                      
      And D.CO05NRODOC = v.CO05NRODOC                     
  Where P.ccm02tipana='02'            
  
  f1-1 +100
  f1   -970 
	   -30 
  CREATE view v_doc2      
  As      
  -- Soles  
  Select pagos.CO05CODEMP,pagos.CO05CODCTE,pagos.CO05TIPDOC,pagos.CO05NRODOC,      
  Round(Sum(pagos.importeSol),2) as importeSol,      
  Round(Sum(pagos.importeDol),2) as importeDol,  
  MAX(Isnull(provision.CO05MONEDA,'S')) as CO05MONEDA  
  from v_documentosPendientesPago  pagos Left Join co05docu provision On  
  pagos.CO05CODEMP = provision.CO05CODEMP  
  And pagos.CO05CODCTE = provision.CO05CODCTE  
  And pagos.CO05TIPDOC = provision.CO05TIPDOC  
  And pagos.CO05NRODOC = provision.CO05NRODOC  
  Group by pagos.CO05CODEMP,pagos.CO05CODCTE,pagos.CO05TIPDOC,pagos.CO05NRODOC  
  Having --(abs(Round(Sum(pagos.importeSol),2))<>0  
  (Case When MAX(Isnull(provision.CO05MONEDA,'S')) ='S' then (abs(Round(Sum(pagos.importeSol),2)))else (abs(Round(Sum(pagos.importeDol),2)))End)<>0   
 
 Select CO05CODEMP,CO05CODCTE,CO05TIPDOC,CO05NRODOC,COUNT(*)
  from    v_documentosPendientesPago group by 
 CO05CODEMP,CO05CODCTE,CO05TIPDOC,CO05NRODOC
 Having COUNT(*)>2
 
  Select *
  from    v_documentosPendientesPago where CO05CODCTE='10076378181' and CO05NRODOC='001-000025'
  -- Deisi
  ivan-001  05/05	x 2000		mayo
								Junio
					x1000
								te pago 1000 efectivo
						
						fac provisionadas not in (pagadas)
						Nota credito
						facturas x partes
						facturas reencion
						facturas detraccion
						 	  
  
  
 01	10076378181	01	001-000025
 liquidacion:
 planta : necekitas, fieros cemntos, emergencia
 semanalmente te voy 3K y el fin de me qliquidad lo que te he dado:
		3000 
				500 gasolina
				130 interner
				45 comida
				...
				...
				------
				2300
				700 plata
				---
				3000
				
    --modificar
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
  
  select * from traver.dbo.Ban01RetencionDet