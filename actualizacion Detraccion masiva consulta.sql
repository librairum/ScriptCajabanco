use traver
go
--exec Spu_Ban_Trae_DetaraccionMasivaDetalle '01', '251952'
--sp_helptext Spu_Ban_Trae_DetaraccionMasivaDetalle

--select * from Ban01PresupuestoPago where Ban01Numero = '00021' 
--detraccion masivo 03


--exec Spu_Ban_Trae_DetallePresupuestoTemporal '01', '00021'
--exec Spu_Ban_Trae_DetraccionMasivaCab '01', '2025', '06', '03' 
--detraccion masiva
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


  

  --select * from Ban01TipoPago -- medio pago
  --select * from Ban01Banco; -- banco


 --select * from V_PresupuestoTotales -- 23 registros
alter View V_PresupuestoTotales      
As      
Select cp.Ban01Empresa, cp.Ban01Numero, cp.Ban01Anio,cp.Ban01Mes,Ban01motivopagoCod,  
Sum(isnull(dp.Ban02PagoSoles,0)) as ImpBrutoSoles,      
Sum(isnull(dp.Ban02PagoDolares,0)) as ImpBrutoDolares,      
--
      
sum(isnull(dp.Ban02ImporteDetraccionSoles,0)) as ImpDetraccionSoles,      
sum(isnull(dp.ban02ImporteRetencionSoles,0)) as ImpRetencionSoles,      
sum(isnull(dp.Ban02ImportePercepcionSoles,0)) as ImpPercepcionSoles,      
--      
sum(isnull(dp.Ban02ImporteDetraccionDolares,0)) as ImpDetraccionDolares,      
sum(isnull(dp.ban02ImporteRetencionDolares,0)) as ImpRetencionDolares,      
sum(isnull(dp.Ban02ImportePercepcionDolares,0)) as ImpPercepcionDolares,      
--      
(SUM(isnull(dp.Ban02PagoSoles,0)) - (Sum(isnull(dp.Ban02ImporteDetraccionSoles,0)) +  sum(isnull(dp.ban02ImporteRetencionSoles,0)) + sum(isnull(dp.Ban02ImportePercepcionSoles,0)))) as 'ImpNetoSoles',      
(SUM(isnull(dp.Ban02PagoDolares,0)) - 
(Sum(isnull(dp.Ban02ImporteDetraccionDolares,0)) + 
sum(isnull(dp.ban02ImporteRetencionDolares,0)) + sum(isnull(dp.Ban02ImportePercepcionDolares,0)))) as 'ImpNetoDolares'  ,
medioPago.Ban01Descripcion as nombreMedioPago,
banco.Ban01Descripcion as 'nombreBanco', cp.Ban01Descripcion as 'motivo', cp.Ban01Fecha as 'fechaPresupuesto',
banco.Ban01IdBanco as 'bancoCodMedioPago', Ban01DetraMasivaLote
From           
 Ban01PresupuestoPago cp left join  ban02presupuestopagodetalle dp   
	on cp.Ban01Empresa = dp.Ban02Empresa       
	and cp.Ban01Numero = dp.Ban02Numero      
	left join Ban01TipoPago medioPago
	on medioPago.Ban01Empresa = cp.Ban01Empresa
	and medioPago.Ban01IdTipoPago = cp.Ban01MedioPago
	left join Ban01Banco banco 
	on banco.Ban01Empresa = medioPago.Ban01Empresa
	and banco.Ban01IdBanco = medioPago.Ban01CtaBanBancoCod
Group by cp.Ban01Empresa, cp.Ban01Numero,cp.Ban01Anio,cp.Ban01Mes,Ban01motivopagoCod, medioPago.Ban01Descripcion,
banco.Ban01Descripcion, cp.Ban01Descripcion , cp.Ban01Fecha, banco.Ban01IdBanco, cp.Ban01DetraMasivaLote


--select top 5 * from Ban01PresupuestoPago order by Ban01Numero desc
--select * from Ban01TipoPago -- ban01empresa , ban01idtipopago , ban01descripcion
---- Ban01CtaBanBancoCod : id cuenta para amarrar con ban01banco
--Ban01MedioPago '03'
--select * from 