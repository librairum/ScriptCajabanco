
-- Agrego Campo a presupuesto para 
Alter Table  Ban01PresupuestoPago Add Ban01DetraMasivaLote varchar(6)

-- Actulizo con el valor 
Update Ban01PresupuestoPago Set Ban01DetraMasivaLote='251952' Where Ban01Numero='00024'
Update Ban01PresupuestoPago Set Ban01DetraMasivaLote='251953' Where Ban01Numero='00025'

-- Pendiente
Agregar campo, cuando se crea el presupuesto ()


--Exec  Spu_Ban_Trae_DetraccionMasivaCab '01','2025','06','03'
Alter Procedure Spu_Ban_Trae_DetraccionMasivaCab  
@empresa char(2),  
@anio  char(4),  
@mes  char(2),  
@motivopago char(2) -- 03 detraccion masiva  
As  
Select   
CO26CODEMP as 'EmpresaCod',  
CO26AA as 'Anio',  
CO26MES as 'Mes',  
CO26NUMLOTE as 'LoteDetraccionNro',  
'' as 'PresupuestoCod',  
Sum(CO26IMPORTFACT) as 'FacturaImporteSol',   
sum(CO26IMPORTEDETRA) as 'DetraccionImporteSol'  
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
And CO26NUMLOTE not in (Select distinct Ban01DetraMasivaLote from Ban01PresupuestoPago where Ban01Empresa=@empresa and Ban01motivopagoCod='03') -- Detraccion Masiva)
Group by CO26CODEMP,CO26AA,CO26MES,CO26NUMLOTE  

Union All  
Select   
Ban01Empresa as 'EmpresaCod',  
Ban01Anio as 'Anio',   
Ban01Mes as 'Mes',  
'' as 'LoteDetraccionNro',  
Ban01Numero as 'PresupuestoCod',  
ImpBrutoSoles as 'FacturaImporteSol',   
ImpDetraccionSoles as 'DetraccionImporteSol'  
From V_PresupuestoTotales   
Where Ban01Empresa=@empresa and Ban01Anio=@anio and Ban01Mes=@mes and Ban01motivopagoCod=@motivopago -- Detracciones masivas