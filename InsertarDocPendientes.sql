
Alter view V_PrespuestoSeleccionados

Alter view V_Ban01PendientesPresupuesto  


Select * from Ban01PresupuestoPago
Select * from Ban02PresupuestoPagoDetalle

Select * from Fa51TipoDocumento
Select * from FAC01_TIPDOC
Select * from ccb02tipd
Select * from ccb17ana


Exec  Spu_Ban_Trae_DocPendiente '01','10107061199',''

Alter procedure Spu_Ban_Trae_DocPendiente      


Select * From TmpCtaCte Where usuario = 'melissa'
Order By Cuenta,Cuenta_Corriente,Tipo_Documento,Numero_Documento,Fecha_Documento        

--Select * from ccb01rngimp  
--Select top 2 * From ccd        
--SP_HELP CCM02CTA        
--SP_HELP tmpctacte       
Total - pagado = Pendientes

Pagados = Total - Pendientes
        = C005docu - Pendientes cta Corriente
        

Select CO05CODCTE,CO05TIPDOC,CO05NRODOC,CO05MONEDA,
CO05IMPBRU,CO05IMPINA,CO05IMPIGV,CO05IMPPAG,
CO05IMPBDOL,CO05IMPINADOL,CO05IMPIGVDOL,CO05IMPDOL,

ccb02des as 'TipDoc_Nombre'

From co05docu			-- 91,724
Left Join ccb02tipd td On 
	co05docu.CO05CODEMP = td.ccb02emp
 	And CO05TIPDOC = td.ccb02cod

Select * from co05docu -- 91725
Select * from ccb17ana
Select * from ccb02tipd
-- ===
Select * from ccm02cta where ccm02cod='10077505585'
Select * from co05docu where CO05CODCTE='10077505585'
Select * from ccd where ccd01cod='10077505585'
--
Select * from ccm02cta where ccm02cod='10107061199'
Select * from co05docu where CO05CODCTE='10107061199'
Select * from ccd where ccd01cod='10107061199'

Select * from co05docu where CO05MONEDA='D'

Sp_help Ban02PresupuestoPagoDetalle

Select * from Ban02PresupuestoPagoDetalle

Delete from Ban02PresupuestoPagoDetalle

Sp_help Ban02PresupuestoPagoDetalle

Alter Table Ban02PresupuestoPagoDetalle Alter Column Ban02TasaDetraccion decimal(15,2)

Alter Table Ban02PresupuestoPagoDetalle Alter Column Ban02TasaRetencion decimal(15,2)
Alter Table Ban02PresupuestoPagoDetalle Alter Column Ban02TasaPercepcion decimal(15,2)



-- Insertar 
Insert Into Ban02PresupuestoPagoDetalle(Ban02Empresa,Ban02Numero,Ban02Codigo,Ban02Ruc,Ban02Tipodoc,Ban02NroDoc
,Ban02PagoSoles,Ban02PagoDolares
,Ban02TipoDetraccion
,Ban02TasaDetraccion
,Ban02ImporteDetraccionSoles,Ban02ImporteDetraccionDolares,
Ban02TasaRetencion,Ban02ImporteRetencionSoles,Ban02ImporteRetencionDolares,
Ban02TasaPercepcion,Ban02ImportePercepcionSoles,Ban02ImportePercepcionDolares,	
Ban02NetoSoles,Ban02NetoDolares
)
	
Select '01' as 'empresa','00001',RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT CO05CODCTE)) AS VARCHAR(5)), 5) as 'Correlativo',
CO05CODCTE,CO05TIPDOC,CO05NRODOC,
Convert(decimal(18,2),CO05IMPPAG),Convert(decimal(9,2),CO05IMPDOL),
(Case when isnull(CO05AFECTODETRACCION,'S')='S' then Isnull(CO05DETRATIPOPERACION,'') else '' end) as 'Detra_Tipo'
,(Case when isnull(CO05AFECTODETRACCION,'S')='S' then Convert(decimal(9,2),Isnull(CO05DETRAPORCENTAJE,0)) else 0 end) as 'Detra_porcentaje',
(Case when isnull(CO05AFECTODETRACCION,'S')='S' then Convert(decimal(9,2),Isnull(CO05DETRAIMPORTE,0)) else 0 end) as 'Detra_ImpSoles',
(Case when isnull(CO05AFECTODETRACCION,'S')='S' then Convert(decimal(9,2),isnull(CO05DETRAIMPORTE_EQUI,0)) else 0 end) as 'Detra_ImpDolares',
--
(Case when isnull(CO05AFECTORET,'')='S' then 3 else 0 end) as 'Retencion',
(Case when isnull(CO05AFECTORET,'')='S' then Convert(decimal(9,2),(CO05IMPPAG*3/100)) else 0 end) as 'RetencionMontoSoles',
(Case when isnull(CO05AFECTORET,'')='S' then Convert(decimal(9,2),(CO05IMPDOL*3/100)) else 0 end) as 'RetencionMontoDolares',
0 as 'PercepcionTasa',
0 as 'PercepcionSoles',
0 as 'PercepcionDolares',
Convert(decimal(9,2),CO05IMPPAG),Convert(decimal(9,2),CO05IMPDOL)
From Co05docu


-- Eliminar las pendientes
Delete from Ban02PresupuestoPagoDetalle where
(Ban02Ruc	+ Ban02Tipodoc	+ Ban02NroDoc) in (Select (Cuenta_Corriente + Tipo_Documento	+ Numero_Documento) From TmpCtaCte Where usuario = 'melissa' )


(Select * From TmpCtaCte Where usuario = 'melissa' )




	CO05DETRATIPOSERVICIO	


-- 91776
Select top 1000 * from co05docu		where CO05AA='2025' and CO05MES='04' -- 91776

-- ===
Select * '01' as 'empresa','00001',RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT todas.ruc)) AS VARCHAR(5)), 5) as 'Correlativo',
--todas.Ruc,todas.[Tipo Doc],todas.[Nro Documento],
--todas.OrigSoles,todas.OrigDolares
from V_PresupuestoConsulta todas 
Inner Join co05docu docu on 
todas.Ruc = docu.CO05CODCTE
And todas.[Tipo Doc] = docu.CO05TIPDOC 
And todas.[Nro Documento]= docu.CO05NRODOC

left Join TmpCtaCte SinPagar on 
    todas.Ruc = SinPagar.Cuenta_Corriente
And todas.[Tipo Doc] = SinPagar.Tipo_Documento
And todas.[Nro Documento] = SinPagar.Numero_Documento
And SinPagar.usuario = 'melissa' 
Where
Isnull(SinPagar.Cuenta_Corriente,'')=''




Select CO05CODCTE,CO05TIPDOC,CO05NRODOC,COUNT(*) from co05docu
Group by CO05CODCTE,CO05TIPDOC,CO05NRODOC
Having COUNT(*)>1

Select * from co05docu where CO05CODCTE ='10060488474' and CO05TIPDOC='01' and CO05NRODOC='001-033245'
Select * from co05docu where CO05CODCTE ='20121796857' and CO05TIPDOC='14' and CO05NRODOC='05-456-13015'


