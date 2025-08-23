use traver



-- 03 04 00
insert into segformulario  values('0012','pago retencion', '' ,'07')
--select * from segformulario where codigo = '0012'
insert into segmenu values ('0016', 'pago_retencion','03', '04', '00', '', '0012', 'pi pi-fw pi-credit-card', '07')
insert into segmenuxperfil  values('22', '0016', '11111111111111111111', '07')

--select * from segformulario
--where codmodulo = '07'

--insert into segmenuxperfil values(''
--select * from Segusuario  where Codigo = 'melissa' -- 22 




insert into segformulario values('0013', 'consultadocpendiente_ctaxcobrar', '', '07')
insert into segformulario values( '0014', 'consultahistorica_ctaxcobrar', '', '07')


--select * from segmenu where nivel1 = '04'
-- and codmodulo = '07'
-- order by nivel1+nivel2 + nivel3 desc
 
insert into segmenu values ('0017', 'Consulta Doc.Pendiente-CtaxCobrar',
			'04', '04', '00', '', '0013', 'pi pi-fw pi-credit-card', '07')
			
insert into segmenu values ('0018', 'Consulta Doc.Pendiente-CtaxCobrar',
			'04', '05', '00', '', '0014', 'pi pi-fw pi-credit-card', '07')


insert into segmenuxperfil  values('22', '0017', '11111111111111111111', '07')
insert into segmenuxperfil  values('22', '0018', '11111111111111111111', '07')

