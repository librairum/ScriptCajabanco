CREATE procedure Spu_Ban_Ins_AsientoContable          
@Empresa    Char(2),          
@PresupuestoNumero  Varchar(5) ,      
@mensaje varchar(max) output,      
@flag int output      
As          
--begin      
      
  Begin        
  begin transaction      
  -- Traemos los documentos a cancelar          
  Select           
  Ban01Anio, Ban01Mes,Ban01Numero,Ban01Descripcion,Ban01MedioPago,Ban01Fecha,Ban01FechaEjecucionPago,          
  Ban02Empresa,          
  Ban02Ruc,Ban02Tipodoc,Ban02NroDoc,          
  Ban02PagoSoles,Ban02PagoDolares,          
  Ban02TipoDetraccion,Ban02TasaDetraccion,Ban02ImporteDetraccionSoles,Ban02ImporteDetraccionDolares,          
  Ban02TasaRetencion,Ban02ImporteRetencionSoles,Ban02ImporteRetencionDolares,          
  Ban02NetoSoles,Ban02NetoDolares,          
  --Drop table #DocPagados          
  Convert(varchar(20),'') as 'CuentaContableProvision',          
  Convert(char(2),'') as 'VoucherProvisionEmpresa',          
  Convert(char(4),'') as 'VoucherProvisionAnio',          
  Convert(char(2),'') as 'VoucherProvisionMes',          
  Convert(char(2),'') as 'VoucherProvisionLibro',          
  Convert(varchar(5),'') as 'VoucherProvisionNumero'          
  
  --Drop table #DocPagados          
  Into #DocPagados          
  From Ban02PresupuestoPagoDetalle pd inner Join  Ban01PresupuestoPago pc on           
  pd.Ban02Empresa = pc.Ban01Empresa and pd.Ban02Numero = pc.Ban01Numero          
  Where pd.Ban02Empresa=@Empresa and pd.Ban02Numero=@PresupuestoNumero          
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al insertar doc.pagados'      
   --set @flag  = -1      
   Goto ManejaError      
  end      
  --Drop table #DatosParaAsiento          
  Create table #DatosParaAsiento          
  (          
   PresupuestoNro varchar(5),          
   VoucherEmpresa char(2),          
   VoucherAnio  char(4),          
   VoucherMes  char(2),          
   VoucherFecha datetime,           
   VoucherGlosa varchar(80),          
   --          
   VoucherLibro   char(2),          
   VoucherBancosSiglas  varChar(5),          
   VoucherNumero   varchar(5),          
   CuentaContableBancos Varchar(20),          
   CuentaContableItf  Varchar(20),          
   CuentaContableComiOtrosBancos Varchar(20),          
   MonedaDeLaCuenta10  char(1),          
   Ban01AsiConFlagITF  char(1)          
  )          
  
  
  --=== Traer las cuentas donde fueron provisonadas las cuentas a Pagar          
  --Actualizo sus datos contables          
  Update #DocPagados          
  Set          
  VoucherProvisionEmpresa = do.CO05CODEMP,          
  VoucherProvisionAnio = do.CO05AA,          
  VoucherProvisionMes = do.CO05MES,          
  VoucherProvisionLibro = do.CO05LIBRO,          
  VoucherProvisionNumero = do.CO05NUMER          
  From co05docu do where          
  #DocPagados.Ban02Empresa = do.CO05CODEMP          
  And #DocPagados.Ban02Ruc =do.CO05CODCTE          
  And #DocPagados.Ban02Tipodoc=do.CO05TIPDOC          
  And #DocPagados.Ban02NroDoc= do.CO05NRODOC          
  
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al actualizar doc.pagados'      
   --set @flag  = -1      
   Goto ManejaError      
  end      
  -- Actualiza mis cuenta de provision o registro de compras          
  Update #DocPagados          
  Set CuentaContableProvision=Isnull(ccd01cta,'')          
  From ccd where           
  ccd.ccd01emp=VoucherProvisionEmpresa           
  and ccd.ccd01ano=VoucherProvisionAnio          
  and ccd.ccd01mes=VoucherProvisionMes          
  and ccd.ccd01subd=VoucherProvisionLibro          
  and ccd.ccd01numer=VoucherProvisionNumero          
  --          
  and ccd.ccd01cod=Ban02Ruc          
  and ccd.ccd01tipdoc=Ban02Tipodoc          
  and ccd.ccd01ndoc=Ban02NroDoc          
  
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al actualizar doc.pagados'      
   --set @flag  = -1      
   Goto ManejaError      
  end      
  
  Insert into #DatosParaAsiento(PresupuestoNro,VoucherEmpresa,VoucherAnio,VoucherMes,VoucherFecha,VoucherGlosa,   
  VoucherLibro,VoucherBancosSiglas,CuentaContableBancos,CuentaContableItf,CuentaContableComiOtrosBancos,MonedaDeLaCuenta10,          
  Ban01AsiConFlagITF       
  )          
  Select           
  pp.Ban01Numero,          
  pp.Ban01Empresa,pp.Ban01Anio,pp.Ban01Mes,Convert(DATETIME,pp.Ban01FechaEjecucionPago,103),left(pp.Ban01Descripcion,80),          
  Isnull(tp.Ban01AsiConDiario,''),Isnull(Ban01AsiConPrefijo,''),Isnull(tp.Ban01AsiConCtaBanco,''),          
  Isnull(tp.Ban01AsiConCtaITF,''),Isnull(tp.Ban01AsiConCtaComiOtrosBancos,''),Isnull(tp.Ban01Moneda,''),          
  Isnull(Ban01AsiConFlagITF,'')          
  --          
  From Ban01TipoPago tp Inner join Ban01PresupuestoPago pp on          
  tp.Ban01Empresa = pp.Ban01Empresa and tp.Ban01IdTipoPago=pp.Ban01MedioPago          
  Where pp.Ban01Empresa=@Empresa and pp.Ban01Numero=@PresupuestoNumero          
    if @@error <> 0      
    Begin      
    set @mensaje = 'eror al insertar datos para asiento'       
    Goto ManejaError      
    end      
          
  -- Actualiza nro de Voucher          
  --Trae ultimo numero de voucher cn          
  
  Update #DatosParaAsiento Set VoucherNumero=isnull((Select  --@UltimoVouher = Isnull(max(ccc01numer),'00000')           
  --(Max(right(ccc01numer,(5-Len(VoucherBancosSiglas)))) +1),          
  --(max(right(ccc01numer,(5-len(VoucherBancosSiglas)))) +1)          
  VoucherBancosSiglas +           
  (REPLICATE('0',(5-len(VoucherBancosSiglas))-LEN((Max(right(ccc01numer,(5-Len(VoucherBancosSiglas)))) +1))) +          
  Convert(varchar,((Max(right(ccc01numer,(5-Len(VoucherBancosSiglas)))) +1)),5))          
  from ccc Inner Join #DatosParaAsiento          
  on           
  ccc01emp=VoucherEmpresa          
  And ccc01ano=VoucherAnio          
  And ccc01mes=VoucherMes           
  And ccc01subd=VoucherLibro                       
  And left(ccc01numer,len(VoucherBancosSiglas)) in (VoucherBancosSiglas)          
  Group  by VoucherBancosSiglas          
  ),VoucherBancosSiglas + '001')        
  
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al insertar datos para asiento'      
   --set @flag  = -1      
   Goto ManejaError      
  end      
  --          
  Update Ban01PresupuestoPago          
  Set Ban01VoucherLibroCod=VoucherLibro,          
  Ban01VoucherNumero=VoucherNumero          
  from #DatosParaAsiento          
  Where           
  Ban01Empresa=@Empresa and Ban01Numero=@PresupuestoNumero          
  
  
  
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al actualiza prespuesto pago'        
   Goto ManejaError      
  end      
  --Select * from #DatosParaAsiento        
  
  -- ===== Insertar Cabecera Voucher          
  Insert Into ccc(ccc01emp,ccc01ano,ccc01mes,ccc01subd,ccc01numer,ccc01fecha,ccc01deta,ccc01flag,ccc01astip,ccc01trans)                            
  Select VoucherEmpresa,VoucherAnio,VoucherMes,VoucherLibro,VoucherNumero,VoucherFecha,VoucherGlosa,'0','','N' from #DatosParaAsiento          
  --If @@ERROR<>0                    
  -- Begin                    
  --  Set @msgretorno='ERROR : Al Insertar Cabecera Voucher'                    
  --  Goto ManejaError                    
  -- End          
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al insertar cabcecera voucher'        
   Goto ManejaError      
  end      
  
  -- ====== Insertar Detalle          
  -- ====2.Inserto Detalle De Voucher                                
  --2.1 Creo Tabla temporal                                
  Create Table [#ccd_Bancos] (                                
  [ccd01emp] [varchar] (2)  NOT NULL ,                                
  [ccd01ano] [varchar] (4)  NOT NULL ,                  
  [ccd01mes] [varchar] (2)  NOT NULL ,                   
  [ccd01subd] [varchar] (2)  NOT NULL ,                                
  [ccd01numer] [varchar] (5)  NOT NULL ,                                
  [ccd01ord] [float] NOT NULL ,                                
  [ccd01cta] [varchar] (15)  NULL ,                              
  [ccd01deb] [float] NULL ,                                
  [ccd01hab] [float] NULL ,                                
  [ccd01con] [varchar] (80)  NULL ,                
  [ccd01tipdoc] [varchar] (2)  NULL ,                                
  [ccd01ndoc] [varchar] (15)  NULL ,                           
  [ccd01fedoc] [varchar] (10) NULL ,                                
  [ccd01feven] [varchar] (10) NULL ,                                
  [ccd01ana] [varchar] (2)  NULL ,                                
  [ccd01cod] [varchar] (11)  NULL ,               
  [ccd01dn] [varchar] (1)  NULL ,                                
  [ccd01tc] [float] NULL ,                                
  [ccd01afin] [varchar] (1)  NULL ,                                
  [ccd01cc] [varchar] (12)  NULL ,                                
  [ccd01cg] [varchar] (6)  NULL ,                                
  [ccd01fevou] [varchar] (10) NULL ,                                
  [ccd01ama] [varchar] (1)  NULL ,                                
  [ccd01astip] [varchar] (5)  NULL ,                                
  [ccd01val] [varchar] (15)  NULL ,                                
  [ccd01cd] [varchar] (6)  NULL ,                                
  [ccd01car] [float] NULL ,                                
  [ccd01abo] [float] NULL ,                                
  [ccd01trans] [varchar] (1) NULL ,                                
  [ccd01AfectoReteccion] [varchar] (1)  NULL ,                                
  [ccd01FechaRetencion]  [varchar] (10) NULL ,                                
  [ccd01NroDocRetencion] [varchar] (20)  NULL ,                                
  [ccd01TipoTransaccion] [varchar] (2)  NULL ,                                
  [ccd01FechaPagoRetencion] [varchar] (10) NULL ,                                
  [ccd01TipoDocRetencion] [varchar] (2)  NULL ,                                
  [ccd01NroPago] [varchar] (15)  NULL ,                                
  [ccd01FecPago] [varchar] (10) NULL ,                   
  [ccd01porcentaje] [varchar] (2)  NULL ,                                
  [ccd01ams] [varchar] (15)  NULL ,                                
  )                    
  
  
  --          
  
  
  -- Asiento de pago           
  -- Cuenta 10          
  INSERT INTO #ccd_Bancos(ccd01emp,ccd01ano,ccd01mes,ccd01subd,ccd01numer,          
  ccd01ord,ccd01cta,ccd01deb,ccd01hab,ccd01con,ccd01tipdoc,ccd01ndoc,ccd01fedoc,          
  ccd01feven,ccd01ana,ccd01cod,ccd01dn,ccd01tc,ccd01afin,          
  ccd01cc,ccd01cg,ccd01fevou,ccd01ama,ccd01astip,ccd01val,          
  ccd01cd,ccd01car,ccd01abo,ccd01trans,          
  ccd01AfectoReteccion,ccd01FechaRetencion,ccd01NroDocRetencion,ccd01TipoTransaccion,          
  ccd01FechaPagoRetencion,ccd01TipoDocRetencion,ccd01NroPago,ccd01FecPago,ccd01porcentaje,ccd01ams)          
  
  
  Select           
  max(da.VoucherEmpresa),max(da.VoucherAnio),max(da.VoucherMes),max(da.VoucherLibro),max(da.VoucherNumero),          
  0,max(da.CuentaContableBancos),0, Sum(dd.Ban02NetoSoles) as 'ccd01hab',max(da.VoucherGlosa),'' as tipdoc,'' as numdoc, dbo.ForFechaaTexto(max(da.VoucherFecha)),          
  null as fecven,'' as codana,'' as codctacte,max(da.MonedaDeLaCuenta10),3.5 as 'TipoCambio','' as ccd01afin,          
  '' as 'ccd01cc','' as 'ccd01cg',dbo.ForFechaaTexto(max(da.VoucherFecha)) as 'ccd01fevou','' as ccd01ama,'' as ccd01astip,'' as ccd01val,          
  '' as 'ccd01cd',0 as 'ccd01car',(Sum(dd.Ban02NetoSoles)/3.5) as 'ccd01abo','' as 'ccd01trans',                                
  '' as 'ccd01AfectoReteccion',Null as 'ccd01FechaRetencion','' as 'ccd01NroDocRetencion','' as 'ccd01TipoTransaccion',                                
  Null as ccd01FechaPagoRetencion,'' as 'ccd01TipoDocRetencion','' as 'ccd01NroPago', Null as 'ccd01FecPago',Null as 'ccd01porcentaje','' as 'ccd01ams'          
  From #DocPagados dd Inner join #DatosParaAsiento da on           
  dd.Ban02Empresa = da.VoucherEmpresa          
  And dd.Ban01Numero = da.PresupuestoNro          
  Group by CuentaContableBancos,Ban01FechaEjecucionPago          
  if @@error <> 0      
  Begin      
   set @mensaje = 'Error al insertar cuenta 10'        
   Goto ManejaError      
  end      
  -- Cuenta 42          
  INSERT INTO #ccd_Bancos(ccd01emp,ccd01ano,ccd01mes,ccd01subd,ccd01numer,          
  ccd01ord,ccd01cta,ccd01deb,ccd01hab,ccd01con,ccd01tipdoc,ccd01ndoc,ccd01fedoc,          
  ccd01feven,ccd01ana,ccd01cod,ccd01dn,ccd01tc,ccd01afin,          
  ccd01cc,ccd01cg,ccd01fevou,ccd01ama,ccd01astip,ccd01val,          
  ccd01cd,ccd01car,ccd01abo,ccd01trans,          
  ccd01AfectoReteccion,ccd01FechaRetencion,ccd01NroDocRetencion,ccd01TipoTransaccion,          
  ccd01FechaPagoRetencion,ccd01TipoDocRetencion,ccd01NroPago,ccd01FecPago,ccd01porcentaje,ccd01ams)                
  Select da.VoucherEmpresa,da.VoucherAnio,da.VoucherMes,da.VoucherLibro,da.VoucherNumero,          
  0,CuentaContableProvision,Ban02NetoSoles,0,VoucherGlosa,Ban02Tipodoc,Ban02NroDoc,dbo.ForFechaaTexto(Ban01FechaEjecucionPago),          
  null as fecven,'02' as codana,Ban02Ruc as codctacte,MonedaDeLaCuenta10,3.5,'' as ccd01afin,          
  '' as 'ccd01cc','' as 'ccd01cg',dbo.ForFechaaTexto(Ban01FechaEjecucionPago) as 'ccd01fevou','' asccd01ama,'' as ccd01astip,'' as ccd01val,          
  '' as 'ccd01cd',(Ban02NetoSoles/3.5) as 'ccd01car',0 as 'ccd01abo','' as 'ccd01trans',                                
  '' as 'ccd01AfectoReteccion',Null as 'ccd01FechaRetencion','' as 'ccd01NroDocRetencion','' as 'ccd01TipoTransaccion',                                
  Null as ccd01FechaPagoRetencion,'' as 'ccd01TipoDocRetencion','' as 'ccd01NroPago', Null as 'ccd01FecPago',Null as 'ccd01porcentaje','' as 'ccd01ams'          
  From #DocPagados dd Inner join #DatosParaAsiento da on           
  dd.Ban02Empresa = da.VoucherEmpresa          
  And dd.Ban01Numero = da.PresupuestoNro          
  
  
  if @@error <> 0      
  Begin      
   set @mensaje = 'error al insertar cuenta 42'      
   Goto ManejaError      
  end      
  
  
  
  
  -- Asiento de ITF, en caso sea transferencia bancaria          
  -- Cuenta 10           
  If(Select counT(Ban01AsiConFlagITF) from #DatosParaAsiento where isnull(Ban01AsiConFlagITF,'')='S')>0          
  Begin          
   -- Cuenta 10          
   INSERT INTO #ccd_Bancos(ccd01emp,ccd01ano,ccd01mes,ccd01subd,ccd01numer,          
   ccd01ord,ccd01cta,ccd01deb,ccd01hab,ccd01con,ccd01tipdoc,ccd01ndoc,ccd01fedoc,          
   ccd01feven,ccd01ana,ccd01cod,ccd01dn,ccd01tc,ccd01afin,          
   ccd01cc,ccd01cg,ccd01fevou,ccd01ama,ccd01astip,ccd01val,          
   ccd01cd,ccd01car,ccd01abo,ccd01trans,          
   ccd01AfectoReteccion,ccd01FechaRetencion,ccd01NroDocRetencion,ccd01TipoTransaccion,          
   ccd01FechaPagoRetencion,ccd01TipoDocRetencion,ccd01NroPago,ccd01FecPago,ccd01porcentaje,ccd01ams)          
  
   Select           
   max(da.VoucherEmpresa),max(da.VoucherAnio),max(da.VoucherMes),max(da.VoucherLibro),max(da.VoucherNumero),          
   0,max(da.CuentaContableBancos),0, dbo.Fn_CalcularITF(Sum(dd.Ban02NetoSoles)) as 'ccd01hab',max(da.VoucherGlosa),'' as tipdoc,'' as numdoc, dbo.ForFechaaTexto(max(da.VoucherFecha)),          
   null as fecven,'' as codana,'' as codctacte,max(da.MonedaDeLaCuenta10),3.5 as 'TipoCambio','' as ccd01afin,          
   '' as 'ccd01cc','' as 'ccd01cg',dbo.ForFechaaTexto(max(da.VoucherFecha)) as 'ccd01fevou','' as ccd01ama,'' as ccd01astip,'' as ccd01val,          
   '' as 'ccd01cd',0 as 'ccd01car',dbo.Fn_CalcularITF((Sum(dd.Ban02NetoSoles)/3.5)) as 'ccd01abo','' as 'ccd01trans',                                
   '' as 'ccd01AfectoReteccion',Null as 'ccd01FechaRetencion','' as 'ccd01NroDocRetencion','' as 'ccd01TipoTransaccion',                                
   Null as ccd01FechaPagoRetencion,'' as 'ccd01TipoDocRetencion','' as 'ccd01NroPago', Null as 'ccd01FecPago',Null as 'ccd01porcentaje','' as 'ccd01ams'          
   From #DocPagados dd Inner join #DatosParaAsiento da on           
   dd.Ban02Empresa = da.VoucherEmpresa          
   And dd.Ban01Numero = da.PresupuestoNro          
   Group by CuentaContableBancos,Ban01FechaEjecucionPago          
  
  
   if @@error <> 0      
   Begin      
    set @mensaje = 'Error al insertar Asiento ITF cuenta 10'      
    Goto ManejaError      
   end      
  
  
   -- Cuenta 9 de ITF          
   INSERT INTO #ccd_Bancos(ccd01emp,ccd01ano,ccd01mes,ccd01subd,ccd01numer,          
   ccd01ord,ccd01cta,ccd01deb,ccd01hab,ccd01con,ccd01tipdoc,ccd01ndoc,ccd01fedoc,          
   ccd01feven,ccd01ana,ccd01cod,ccd01dn,ccd01tc,ccd01afin,          
   ccd01cc,ccd01cg,ccd01fevou,ccd01ama,ccd01astip,ccd01val,          
   ccd01cd,ccd01car,ccd01abo,ccd01trans,          
   ccd01AfectoReteccion,ccd01FechaRetencion,ccd01NroDocRetencion,ccd01TipoTransaccion,          
   ccd01FechaPagoRetencion,ccd01TipoDocRetencion,ccd01NroPago,ccd01FecPago,ccd01porcentaje,ccd01ams)          
  
   Select           
   max(da.VoucherEmpresa),max(da.VoucherAnio),max(da.VoucherMes),max(da.VoucherLibro),max(da.VoucherNumero),          
   0,max(da.CuentaContableItf), dbo.Fn_CalcularITF(Sum(dd.Ban02NetoSoles)) as 'ccd01hab',0,max(da.VoucherGlosa),'' as tipdoc,'' as numdoc, dbo.ForFechaaTexto(max(da.VoucherFecha)),          
   null as fecven,'' as codana,'' as codctacte,max(da.MonedaDeLaCuenta10),3.5 as 'TipoCambio','' as ccd01afin,          
   '' as 'ccd01cc','' as 'ccd01cg',dbo.ForFechaaTexto(max(da.VoucherFecha)) as 'ccd01fevou','' as ccd01ama,'' as ccd01astip,'' as ccd01val,          
   '' as 'ccd01cd',dbo.Fn_CalcularITF((Sum(dd.Ban02NetoSoles)/3.5)) as 'ccd01car',0 as 'ccd01abo','' as 'ccd01trans',                                
   '' as 'ccd01AfectoReteccion',Null as 'ccd01FechaRetencion','' as 'ccd01NroDocRetencion','' as 'ccd01TipoTransaccion',                                
   Null as ccd01FechaPagoRetencion,'' as 'ccd01TipoDocRetencion','' as 'ccd01NroPago', Null as 'ccd01FecPago',Null as 'ccd01porcentaje','' as 'ccd01ams'          
   From #DocPagados dd Inner join #DatosParaAsiento da on           
   dd.Ban02Empresa = da.VoucherEmpresa          
   And dd.Ban01Numero = da.PresupuestoNro          
   Group by CuentaContableBancos,Ban01FechaEjecucionPago          
  
  
   if @@error <> 0      
   Begin      
    set @mensaje = 'Error al insertar Asiento ITF cuenta 9'      
    Goto ManejaError      
   end      
  
  
  End          
  
  
  -- ===== Insertar Detalle Voucher                    
  
  -- Inserto En el Detalle                                  
  -- Declaro Cursor que Arma El Asiento                                
  DECLARE @ccd01emp  varchar(2)                             
  DECLARE @ccd01ano  varchar(4)                                
  DECLARE @ccd01mes  varchar(2)             
  DECLARE @ccd01subd  varchar(2)                                
  DECLARE @ccd01numer  varchar(5)                                
  DECLARE @ccd01ord  float                                
  DECLARE @ccd01cta  varchar(15)                                
  DECLARE @ccd01deb  float                                
  DECLARE @ccd01hab  float                                
  DECLARE @ccd01con  varchar(80)                                
  DECLARE @ccd01tipdoc  varchar(2)                                
  DECLARE @ccd01ndoc  varchar(15)                                
  DECLARE @ccd01fedoc  varchar(10)       
  DECLARE @ccd01feven  varchar(10)                                
  DECLARE @ccd01ana  varchar(2)                                
  DECLARE @ccd01cod  varchar(11)                                
  DECLARE @ccd01dn  varchar(1)                                
  DECLARE @ccd01tc  float                            
  DECLARE @ccd01afin  varchar(1)                                
  DECLARE @ccd01cc  varchar(12)                                
  DECLARE @ccd01cg  varchar(6)                                
  DECLARE @ccd01fevou  varchar(10)                                
  DECLARE @ccd01ama  varchar(1)                                
  DECLARE @ccd01astip  varchar(5)                                
  DECLARE @ccd01val  varchar(15)                                
  DECLARE @ccd01cd  varchar(6)                                
  DECLARE @ccd01car  float                                
  DECLARE @ccd01abo  float                                
  DECLARE @ccd01trans  varchar(1)       
  DECLARE @ccd01AfectoReteccion  varchar(1)                                
  DECLARE @ccd01FechaRetencion   varchar(10)                                
  DECLARE @ccd01NroDocRetencion  varchar(20)                                
  DECLARE @ccd01TipoTransaccion  varchar(2)                                
  DECLARE @ccd01FechaPagoRetencion  varchar(10)                                
  DECLARE @ccd01TipoDocRetencion   varchar(2)                                
  DECLARE @ccd01NroPago   varchar(15)                                
  DECLARE @ccd01FecPago   varchar(10)                                
  DECLARE @ccd01porcentaje  varchar(2)                                
  DECLARE @ccd01ams   varchar(15)                                
  DECLARE @ccd01ord_auto   int            
  --                             
  
  DECLARE @nOkDestino int                
  DECLARE @MsgRetorno varchar(100)          
  
  
  Declare Asiento CURSOR FOR                                
  
  Select   ccd01emp,ccd01ano,ccd01mes,ccd01subd,ccd01numer,ccd01ord,ccd01cta,ccd01deb,                                
  ccd01hab,ccd01con,ccd01tipdoc,ccd01ndoc,ccd01fedoc,ccd01feven,ccd01ana,                                
  ccd01cod,ccd01dn,ccd01tc,ccd01afin,ccd01cc,ccd01cg,ccd01fevou,ccd01ama,                                
  ccd01astip,ccd01val,ccd01cd,ccd01car,ccd01abo,ccd01trans,ccd01AfectoReteccion,                                
  ccd01FechaRetencion,ccd01NroDocRetencion,ccd01TipoTransaccion,ccd01FechaPagoRetencion,                                
  ccd01TipoDocRetencion,ccd01NroPago,ccd01FecPago,ccd01porcentaje,ccd01ams                                
  From #ccd_Bancos          
  Order by ccd01emp,ccd01ano,ccd01mes,ccd01subd,ccd01numer                                
  
  OPEN Asiento                                
  
  Fetch Next From Asiento                                
  Into    @ccd01emp,@ccd01ano,@ccd01mes,@ccd01subd,@ccd01numer,@ccd01ord,@ccd01cta,@ccd01deb,                                
  @ccd01hab,@ccd01con,@ccd01tipdoc,@ccd01ndoc,@ccd01fedoc,@ccd01feven,@ccd01ana,                                
  @ccd01cod,@ccd01dn,@ccd01tc,@ccd01afin,@ccd01cc,@ccd01cg,@ccd01fevou,@ccd01ama,                                
  @ccd01astip,@ccd01val,@ccd01cd,@ccd01car,@ccd01abo,@ccd01trans,@ccd01AfectoReteccion,                                
  @ccd01FechaRetencion,@ccd01NroDocRetencion,@ccd01TipoTransaccion,@ccd01FechaPagoRetencion,                                
  @ccd01TipoDocRetencion,@ccd01NroPago,@ccd01FecPago,@ccd01porcentaje,@ccd01ams                                
  
  While @@FETCH_STATUS = 0                                
  Begin                                
  
    EXECUTE @nOkDestino = Sp_Con_Ins_Detalle_Voucher                                 
    @ccd01emp,@ccd01ano,@ccd01mes,@ccd01subd,@ccd01numer,@ccd01cta,                    
    @ccd01deb,@ccd01hab,@ccd01con,@ccd01tipdoc,@ccd01ndoc,@ccd01fedoc,@ccd01feven,                             
    @ccd01cod,@ccd01dn,@ccd01tc,@ccd01afin,@ccd01cc,@ccd01cg,             
  
    @ccd01astip,@ccd01val,@ccd01car,@ccd01abo,@ccd01trans,@ccd01ama,                                
    @ccd01AfectoReteccion,@ccd01TipoTransaccion,@ccd01NroDocRetencion,@ccd01FechaRetencion,                                
    @ccd01FechaRetencion,                                
    @ccd01TipoDocRetencion,@ccd01NroPago,@ccd01FecPago,                                
    @ccd01porcentaje,            
    '', -- as @ccm01ams,            
    Null,-- as @ccd01Comprobante, --36                    
    Null,-- as @ccd01aniodua, --37                         
    Null,-- as @ccd01codtraencurso,  --38                    
    Null,-- as @ccd01codmaquina,  --39                    
    Null,-- as @ccd01cqmtipo,            
    Null,-- as @ccd01cqmnumero,            
    Null,-- as @ccd01cqmfecha,      
    @ccd01ord_auto   Output,                  
    @MsgRetorno Output                                
  
   If @nOkDestino = -1                                
   Begin                                
    Set  @MsgRetorno = 'No se Pudo Insertar Detalle del Voucher'                                
    GOTO ManejaError                                
   End          
  
   FETCH NEXT FROM Asiento                                
   INTO @ccd01emp,@ccd01ano,@ccd01mes,@ccd01subd,@ccd01numer,@ccd01ord,@ccd01cta,@ccd01deb,                                
   @ccd01hab,@ccd01con,@ccd01tipdoc,@ccd01ndoc,@ccd01fedoc,@ccd01feven,@ccd01ana,                                
   @ccd01cod,@ccd01dn,@ccd01tc,@ccd01afin,@ccd01cc,@ccd01cg,@ccd01fevou,@ccd01ama,                                
   @ccd01astip,@ccd01val,@ccd01cd,@ccd01car,@ccd01abo,@ccd01trans,@ccd01AfectoReteccion,                                
   @ccd01FechaRetencion,@ccd01NroDocRetencion,@ccd01TipoTransaccion,@ccd01FechaPagoRetencion,                                
   @ccd01TipoDocRetencion,@ccd01NroPago,@ccd01FecPago,@ccd01porcentaje,@ccd01ams                                
  End                                
  
  CLOSE Asiento                                
  DEALLOCATE Asiento        
  
  set @flag = 1      
  set @mensaje = 'Asiento contable generado OK'      
  commit transaction  
  return 1      
  
  ManejaError:      
  set @flag = -1      
  rollback transaction  
  return -1      
End 

go

CREATE Procedure Spu_Ban_Ins_PresupuestoRetencionMensual
@Ban01Empresa varchar(2),                          
@Ban01Anio varchar(4),                            
@Ban01Mes varchar(2),                            
@Ban01Descripcion varchar(400),        
                    
@Ban01Fecha varchar(10),    -- se asignara la fecha desde el web frontend del metodo actualiza comprobante                      
@Ban01Estado varchar(2),      
@Ban01Usuario varchar(15),                            
@Ban01Pc varchar(20

),                            
@Ban01FechaRegistro varchar(10),                       
@Ban01MedioPago     char(2),              
@RetencionMensualNro  varchar(6),          -- es el año + mes 
@Ban01motivopagoCod char(2), -- el 03 es pagoi detraccion Masi
vo        
-- Agregar los campos del pago           
--@fechapago VARCHAR(10),      -- formulario web  frontend parametro del metod actualiza comprobante      
@numerooperacion VARCHAR(10),      --formulario web frontend del metod actualiza comprobante   
   
@enlacepago VARCHAR(MAX),      --formulario web  frontend del metod actualiza comprobante      
@nombreArchivo VARCHAR(MAX),      -- formulario web frontend del metod actualiza comprobante      
@contenidoArchivo VARBINARY(MAX),      --formulario web 
frotend del metod actualiza comprobante      
@flagOperacion CHAR(1),      --formulario web frontend del metodo actualiza comprobante      
          
---------------------                            
@flag int output,            
@mensaje varchar(200) ou
tput,            
@codigoGenerado varchar(5) output            
--           
as                            
Begin transaction      
-- Genera correlativo del presipuesto          
declare @ultimoCodigo     varchar(5)          
select @ultimoCodigo = dbo.
ObtenerCorrelativoFormateado(ISNULL(mAX(RIGHT(Ban01Numero,4)),0)+1) from Ban01PresupuestoPago                
Select @ultimoCodigo          
          
          
-- Insertar Cabecera                  
Insert into Ban01PresupuestoPago(Ban01Numero,Ban01Emp
resa,Ban01Anio,Ban01Mes,Ban01motivopagoCod,Ban01Descripcion,Ban01Fecha,
Ban01Estado,Ban01Usuario,Ban01Pc,Ban01FechaRegistro,Ban01MedioPago, Ban01DetraMasivaLote)

Values (@ultimoCodigo, @Ban01Empresa, @Ban01Anio,@Ban01Mes, @Ban01motivopagoCod,
 @Ban01Desc
ripcion, @Ban01Fecha, @Ban01Estado, @Ban01Usuario, @Ban01Pc,               
 @Ban01Fecha, @Ban01MedioPago, @RetencionMensualNro ) 
              
    if @@ERROR <> 0      
    Begin      
  set @mensaje = 'Error al registrar cabecera detraccion'      
  G
oto ManejaError      
    end      
          
-- Insertar Detalle         

Declare @ruc varchar(20)                          
Set @ruc=''                          
Select @ruc=isnull(Ruc,'') from Empresa where Codigo=@Ban01Empresa and Sistema='CONTABILID'              
--Select @ruc        Select * from Empresa     
  

Insert Into Ban02PresupuestoPagoDetalle(Ban02Empresa,Ban02Numero,Ban02Codigo,Ban02Ruc,Ban02Tipodoc,Ban02NroDoc          
,Ban02PagoSoles,Ban02PagoDolares  
        
,Ban02TipoDetraccion          
,Ban02TasaDetraccion          
,Ban02ImporteDetraccionSoles,Ban02ImporteDetraccionDolares,          
Ban02TasaRetencion,Ban02ImporteRetencionSoles,Ban02ImporteRetencionDolares,          
Ban02TasaPercepcion,Ban02Imp
ortePercepcionSoles,Ban02ImportePercepcionDolares,           
Ban02NetoSoles,Ban02NetoDolares          
)          
          
Select    
 rc.Ban01Empresa as 'empresa',@ultimoCodigo,
RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT rd.Ban01Id)) AS VARCHAR(5)), 5) as 'Correlativo',          
   rd.Ban01Ruc  as 'ProveedorRuc',  -- NRO DOC IDENTIDAD             
   rd.Ban01Tipo as 'DocTipo',           
   rd.Ban01NroDoc as 'DocNro',
   isnull(rd.Ban01Retenido,0),
isnull(rd.Ban01RetenidoDolares,0),
'' as 'Detra_Tipo',          
0 as 'Detra_porcentaje',          
0
 as 'Detra_ImpSoles',          
0 as 'Detra_ImpDolares',          
--          
0 as 'RetencionTasa',          
0 as 'RetencionMontoSoles',          
0 as 'RetencionMontoDolares',          
0 as 'PercepcionTasa',          
0 as 'PercepcionSoles',         

 
0 as 'PercepcionDolares',          
isnull(rd.Ban01Retenido,0),
isnull(rd.Ban01RetenidoDolares,0)
From Ban01RetencionCab   rc               
Inner Join Ban01RetencionDet rd on               
rc.Ban01Empresa = rd.Ban01Empresa               
And rc.Ban01Numero = rd.Ban01Numero              
Left join co05docu docu on               
rd.Ban01Ruc = docu.CO05CODCTE              
And rd.Ban01Tipo = docu.CO05TIPDOC              
And rd.Ban01NroDoc = docu.CO05NRODOC              
Left Join V_RetencionesTotal vr On                               
rc.Ban01Empresa = vr.Ban01Empresa                              
And rc.Ban01Numero = vr.Ban01Numero                            
-- === Cabecera retencion                           
Left Join [BIZLINKS_PROD21].dbo.SPE_RETENTION r On                          
    r.tipoDocumentoEmisor='6'                          
And r.numeroDocumentoEmisor=@ruc                          
And r.tipoDocumento='20'                          
And rc.Ban01Numero = r.serieNumeroRetencion                          
-- === Response retencion                          
Left Join [BIZLINKS_PROD21].dbo.VW_SPE_RETENTION_RESPONSE vrr on                          
    vrr.tipoDocumentoEmisor='6'                          
And vrr.numeroDocumentoEmisor=@ruc                          
And vrr.tipoDocumento='20'                          
And rc.Ban01Numero = vrr.serieNumeroRetencion                          
Left Join [BIZLINKS_PROD21].dbo.SPE_CANCELDETAIL_CRE_CPE  rdb on                                 
 rc.Ban01Numero = rdb.serieDocumentoRevertido + '-' + rdb.correlativoDocRevertido                          
 And rdb.tipoDocumentoRevertido ='20'                          
Left Join [BIZLINKS_PROD21].dbo.SPE_CANCELHEADER_CRE_CPE  rcb on                                 
     rcb.tipoDocumentoEmisor =rdb.tipoDocumentoEmisor                          
 And rcb.numeroRucEmisor =rdb.numeroRucEmisor                          
 And rcb.serieNumeroReversion = rdb.serieNumeroReversion                          
Where                                  
rc.Ban01Empresa=@Ban01Empresa
And (rc.Ban01Anio + rc.Ban01Mes)= (@Ban01Anio + @Ban01Mes)
Order by rc.Ban01Numero              
          
      
if @@ERROR  <> 0       
begin      
 set @mensaje = 'Error al registrar detalle Retencion'      
 Goto ManejaError      
end          
--Select *  from CO26PAGODETRACCION where CO26CODEMP='01' and CO26NUMLOTE='200710'          
      
de
clare @flagComprobante as int       
declare @mensajeComprobante as varchar(100)      

Exec Spu_Ban_Upd_ComprobantePago @Ban01Empresa,@Ban01Anio,       
@Ban01Mes, @ultimoCodigo, @Ban01Fecha, @numerooperacion, @enlacepago,      
@nombreArchivo,@contenido
Archivo,@flagOperacion, @flagComprobante out , @mensajeComprobante out      
      
      
set @flag = 1      
set @mensaje = 'El Pago Retencion se registro exitosamente'      
commit transaction      
return 1      
ManejaError:      
set @flag = -1     
 
set @mensaje = 'Error al registrar pago de Retencion'      
rollback transaction
return -1

go

create Procedure Spu_Ban_Trae_DetallePresupuestoDetraIndividual    
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
     dpp.Ban02Soles, dpp.Ban02Dolares,         
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
     dpp.[Ban02ImportePercepcionDolares],        
     dpp.[Ban02NetoSoles],        
     dpp.[Ban02NetoDolares]  ,      
     dpp.Ban02FechaEmision,      
     dpp.Ban02FechaVencimiento  , dpp.Ban02TipoCambio  ,
	comprobante.CO05IMPDOL as importecomprobantedolares,
	comprobante.CO05IMPORT as importecomprobantesoles

   From Ban02PresupuestoPagoDetalle dpp        
   left join FAC01_TIPDOC tipodoc        
   on dpp.Ban02Empresa = tipodoc.FAC01CODEMP        
   and dpp.Ban02Tipodoc = tipodoc.FAC01COD        
   inner join  co05docu comprobante
   on comprobante.CO05CODEMP = dpp.Ban02Empresa
   and comprobante.CO05CODCTE = dpp.Ban02Ruc
   and comprobante.CO05NRODOC = dpp.Ban02NroDoc
   and comprobante.CO05TIPDOC = dpp.Ban02Tipodoc
   
   
   where Ban02Empresa = @Empresa         
   and Ban02Numero = @numeroPresupuesto             
  END  
  eLSE  
  bEGIN  
     select ROW_NUMBER() over(order by ban02codigo asc)  as Item, Ban02Codigo , Ban02Ruc,     
   dbo.ObtenerNombreCta(@Empresa,dpp.Ban02Ruc)  as RazonSocial,        
     isnull(tipodoc.FAC01DESC,'') as NombreTipoDocumento,   dpp.Ban02NroDoc, dpp.Ban02Moneda,         
     (case dpp.Ban02Moneda when 'S' then 'SOLES' ELSE 'DOLARES' END) AS NOMBREMONEDA,        
     dpp.Ban02Soles, dpp.Ban02Dolares,         
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
     dpp.[Ban02ImportePercepcionDolares],        
     dpp.[Ban02NetoSoles],        
     dpp.[Ban02NetoDolares]  ,      
     dpp.Ban02FechaEmision,      
     dpp.Ban02FechaVencimiento  , dpp.Ban02TipoCambio  ,  
        comprobante.CO05IMPDOL as importecomprobantedolares,
	comprobante.CO05IMPORT as importecomprobantesoles
   From Ban02PresupuestoPagoDetalle dpp        
   left join FAC01_TIPDOC tipodoc        
   on dpp.Ban02Empresa = tipodoc.FAC01CODEMP        
   and dpp.Ban02Tipodoc = tipodoc.FAC01COD        
            inner join  co05docu comprobante
   on comprobante.CO05CODEMP = dpp.Ban02Empresa
   and comprobante.CO05CODCTE = dpp.Ban02Ruc
   and comprobante.CO05NRODOC = dpp.Ban02NroDoc
   and comprobante.CO05TIPDOC = dpp.Ban02Tipodoc
   where Ban02Empresa = @Empresa         
   and Ban02Numero = @numeroPresupuesto    
  eND  
    
End

go

CREATE procedure Spu_ban_trae_InterbankArchivo    
@Ban01Empresa varchar(2),  
@Ban01Numero varchar(5)  
as    
Begin    
  
   SELECT     
    '02' AS CodigoRegistro,    
    BPD.Ban02Ruc + REPLICATE('0', 20-LEN(BPD.Ban02Ruc)) AS CodigoBeneficiario,    
    (case BPD.Ban02Tipodoc when '01' then 'F' Else 'O' end) AS TipoDocumentoPago,    
    replace(BPD.Ban02NroDoc,'-','') + replicate('0',20-len(replace(BPD.Ban02NroDoc,'-',''))) AS NumeroDocumentoPago,
     right(BPD.Ban02FechaVencimiento, 4)
      + SUBSTRING(BPD.Ban02FechaVencimiento, 4,2) +SUBSTRING(BPD.Ban02FechaVencimiento, 1,2) as FechaVencimiento,
    (case BPD.Ban02Moneda
     when  'D' then '10' else '01' end) AS MonedaAbono,         
     (case BPD.Ban02Moneda when 'D' then dbo.ConvertirFormatoAbono(BPD.Ban02NetoDolares)    
     else dbo.ConvertirFormatoAbono(BPD.Ban02NetoSoles) end)    
    AS MontoAbono,    
    --BPD.Ban02NetoDolares,    
    '' AS IndicadorBanco,    
       
    '09' AS TipoAbono,        
    '' as TipoCuenta,    
   
    CASE     
     WHEN LEN(BPD.Ban02Ruc) = 11 THEN '2'     
     ELSE '1'     
    END AS TipoPersona,    
       
    BPD.Ban02Tipodoc AS TipoDocumentoIdentidad,    
    BPD.Ban02Ruc AS NumeroDocumentoIdentidad,    
    BPD.Ban02GiroOrden AS NombreBeneficiario,    
    NULL AS MonedaMontoIntangibleCTS,    
    NULL AS MontoIntangibleCTS,    
       
    -- Filler vacío    
    '' AS Filler,    
       
    -- Celular    
    NULL AS NumeroCelular,    
       
    -- Correo    
    NULL AS CorreoElectronico    
       
   FROM   Ban02PresupuestoPagoDetalle BPD    
    INNER JOIN Ban01PresupuestoPago PP     
     ON BPD.Ban02Numero = PP.Ban01Numero     
       AND BPD.Ban02Empresa = PP.Ban01Empresa    
   Where  
   PP.Ban01Empresa = @Ban01Empresa
   And PP.Ban01Numero  = @Ban01Numero
   
End 
go
CREATE procedure Spu_Ban_Trae_InterbankDetArchivo  
@codigoEmpresa char(2),  
@numeroPresupuesto varchar(5)  
as  
Begin  
  
--------cte tipo abono  
with CteTipoAbono as (  
select Ban01IdTipoPago,  
   ctabcoProv.ccm04entidadcod as numeroDocIdentidad,   
 (case when mediopago.Ban01IdTipoPago = '01'  -- cheque   
 then '11' else    
  (case   
   when ctabcoProv.ccm04bancocod = mediopago.Ban01CtaBanBancoCod  -- si es mismo banco interbank  
    then '09'   
    else '99'  -- interbancario  
   end)  
  end) as TipoAbono  
    from ccm04ctabancaria ctabcoProv  
  inner join Ban01TipoPago mediopago  
  on ctabcoProv.ccm04emp = mediopago.Ban01Empresa  
  and ctabcoProv.ccm04bancocod = mediopago.Ban01CtaBanBancoCod  
  where ctabcoProv.ccm04emp = '01'
  --where ctabcoProv.ccm04emp = @codigoEmpresa  
  and ctabcoProv.ccm04ctadefecto = 'S'   
and Ban01IdTipoPago = '04') -- empresa 01 , banco interbank pago soles 04  
    
  
 SELECT       
    '02' AS 'codigoRegistro',  
    presupuestoDet.Ban02Ruc + REPLICATE(' ', 20-LEN(presupuestoDet.Ban02Ruc)) AS 'codigoBeneficiario',  
    (case presupuestoDet.Ban02Tipodoc when '01' then 'F' Else 'O' end) AS 'tipoDocumentoPago',      
    replace(presupuestoDet.Ban02NroDoc,'-','')   
    + replicate(' ',20-len(replace(presupuestoDet.Ban02NroDoc,'-',''))) AS 'numeroDocumentoPago',      
      
      
      isnull(
      right(presupuestoDet.Ban02FechaVencimiento, 4)             
      + SUBSTRING(presupuestoDet.Ban02FechaVencimiento, 4,2)   
      +SUBSTRING(presupuestoDet.Ban02FechaVencimiento, 1,2),'') as 'fechaVencimientoDocumento',      
          
      
         
    (case presupuestoDet.Ban02Moneda       
     when  'D' then '10' else '01' end) AS 'monedaAbono',      
             
  
          
     (case presupuestoDet.Ban02Moneda when 'D'   
     then dbo.ConvertirFormatoAbono(presupuestoDet.Ban02NetoDolares)      
     else dbo.ConvertirFormatoAbono(presupuestoDet.Ban02NetoSoles) end)      
    AS 'montoAbono',      
      
    ' ' AS 'indicadorBanco',      
         
       --Tipo de abono  
  
  
       cteAbono.TipoAbono as 'tipoAbono',  
         
         
(case  when cteAbono.TipoAbono = '09'    
then    
 (case   
 when ctabcoProv.ccm04tipocuenta = 'C'    
 then '001'  
 when  ctabcoProv.ccm04tipocuenta = 'A'   
 then '002' else ''   
 end)  
 when cteAbono.TipoAbono = '09' then ''  
 when cteAbono.TipoAbono = '11' then ''  
   else '' end) as  'tipoCuenta'    
  
,(case when cteAbono.TipoAbono = '09' then   
 (  
  (case when ccm04moneda = 'S' then '01' else '10' end)  
  
 )  
 when cteAbono.TipoAbono = '99' then ''  
 when cteAbono.TipoAbono = '11' then ''  
 end) as 'monedaCuenta'  
 ,  (case when  cteAbono.TipoAbono = '09'   
 then substring(ccm04nrocuenta,1,3)  
   
 when  cteAbono.TipoAbono = '99' then ''   
 when  cteAbono.TipoAbono = '11' then ''   
 else ''  
 end)  as 'oficinaCuenta'  
,   
  
  
(case when cteAbono.TipoAbono = '09'   
   then (SUBSTRING(ccm04nrocuenta,4,LEN(ccm04nrocuenta))   
       + REPLICATE(' ',  
       20- len(SUBSTRING(ccm04nrocuenta,4,LEN(ccm04nrocuenta))))  
      )  
  when cteAbono.TipoAbono = '99'   
   then  ccm04nrocuentacci+REPLICATE(' ',20- len(ccm04nrocuentacci))  
   else replicate(' ',20) end) as 'numeroCuenta',  
 --Tipo de persona  
 (case proveedor.ccm02TipoRuc   
  when  '1' then 'P'   
  when  '2' then 'C'  
  end) as 'tipoPersona',  
       (case ccm02tipdocidentidad   
       when  
  
  '6' then '01'   
       when '1' then '02'  
       else '03' end) as 'tipoDocumentoIdentidad',  
        
       ccm02ruc + REPLICATE(' ', 15 - LEN(ccm02ruc)) as 'numeroDocumentoIdentidad' ,  
       ccm02nom+replicate(' ', 60 - len(ccm02nom)) as 'nombreBeneficiario',  
         
       replicate(' ',2) as 'monedaMontoIntagibleCTS',  
       replicate(' ', 15) as  'montoIntangibleCTS',  
       replicate(' ',6) as  'filler',  
          
   
    -- Celular      
    replicate(' ',40) AS 'numeroCelular',      
         
    -- Correo      
    ccm02correo + replicate(' ', 140+LEN(ccm02correo)) AS 'correoElectronico'  
         
   FROM   Ban02PresupuestoPagoDetalle presupuestoDet      
    INNER JOIN Ban01PresupuestoPago prespuestoCab  
     ON presupuestoDet.Ban02Numero = prespuestoCab.Ban01Numero       
       AND presupuestoDet.Ban02Empresa = prespuestoCab.Ban01Empresa                
       
     left join ccm04ctabancaria ctabcoProv -- cta bancaria Proveedor  
     on presupuestoDet.Ban02Empresa = ctabcoProv.ccm04emp  
     and presupuestoDet.Ban02Ruc = ctabcoProv.ccm04entidadcod  
     and ctabcoProv.ccm04ctadefecto = 'S'  
       
     left join ccm02cta proveedor  
     on proveedor.ccm02emp = ctabcoProv.ccm04emp  
 and proveedor.ccm02cod = ctabcoProv.ccm04entidadcod  
 and proveedor.ccm02tipana = ctabcoProv.ccm04tipana  
 and ctabcoProv.ccm04ctadefecto = 'S'  
    
 left join Ban01Banco banco   
 on banco.Ban01Empresa = ctabcoProv.ccm04emp  
 and banco.Ban01IdBanco = ctabcoProv.ccm04bancocod  
   
 LEFT join CteTipoAbono  cteAbono  
 on cteAbono.numeroDocIdentidad = ctabcoProv.ccm04entidadcod  
   
   Where       
   prespuestoCab.Ban01Empresa = @codigoempresa  
   And prespuestoCab.Ban01Numero=@numeroPresupuesto  
  
  
End  

go

CREATE Procedure Spu_Ban_Upd_PresupuestoDetalle            
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
@Ban02NetoSoles decimal(12,3),  
@Ban02NetoDolares decimal(12,3),  
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
,Ban02NetoSoles  = @Ban02NetoSoles  
, Ban02NetoDolares = @Ban02NetoDolares        
        
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

go
CREATE Procedure Spu_Ban_Ins_PresupuestoDetraMasiva           
@Ban01Empresa varchar(2),                          
@Ban01Anio varchar(4),                            
@Ban01Mes varchar(2),                            
@Ban01Descripcion varchar(400),        

                    
@Ban01Fecha varchar(10),    -- se asignara la fecha desde el web frontend del metodo actualiza comprobante                      
@Ban01Estado varchar(2),      
@Ban01Usuario varchar(15),                            
@Ban01Pc varchar(20

),                            
@Ban01FechaRegistro varchar(10),                       
@Ban01MedioPago     char(2),              
@DetraccionLote  varchar(6),          
@Ban01motivopagoCod char(2), -- el 03 es pagoi detraccion Masivo        
-- Agregar lo
s campos del pago           
--@fechapago VARCHAR(10),      -- formulario web  frontend parametro del metod actualiza comprobante      
@numerooperacion VARCHAR(10),      --formulario web frontend del metod actualiza comprobante      
@enlacepago VARCHAR(
MAX),      --formulario web  frontend del metod actualiza comprobante      
@nombreArchivo VARCHAR(MAX),      -- formulario web frontend del metod actualiza comprobante      
@contenidoArchivo VARBINARY(MAX),      --formulario web frotend del metod actual
iza comprobante      
@flagOperacion CHAR(1),      --formulario web frontend del metodo actualiza comprobante      
          
---------------------                            
@flag int output,            
@mensaje varchar(200) output,            
@codig
oGenerado varchar(5) output            
--           
as                            
Begin transaction      
-- Genera correlativo del presipuesto          
declare @ultimoCodigo     varchar(5)          
select @ultimoCodigo = dbo.ObtenerCorrelativoFormat
eado(ISNULL(mAX(RIGHT(Ban01Numero,4)),0)+1) from Ban01PresupuestoPago                
Select @ultimoCodigo          
          
          
-- Insertar Cabecera                  
Insert into Ban01PresupuestoPago(Ban01Numero,Ban01Empresa,Ban01Anio,Ban01Mes,

      
Ban01motivopagoCod,Ban01Descripcion,Ban01Fecha,Ban01Estado,Ban01Usuario,Ban01Pc,Ban01FechaRegistro,          
Ban01MedioPago, Ban01DetraMasivaLote)          
 values (@ultimoCodigo, @Ban01Empresa, @Ban01Anio,@Ban01Mes, @Ban01motivopagoCod,        


 @Ban01Descripcion, @Ban01Fecha, @Ban01Estado, @Ban01Usuario, @Ban01Pc,               
 @Ban01Fecha, @Ban01MedioPago, @DetraccionLote )                 
              
    if @@ERROR <> 0      
    Begin      
  set @mensaje = 'Error al registrar cabecera
 detraccion'      
  Goto ManejaError      
    end      
          
-- Insertar Detalle           
Insert Into Ban02PresupuestoPagoDetalle(Ban02Empresa,Ban02Numero,Ban02Codigo,Ban02Ruc,Ban02Tipodoc,Ban02NroDoc          
,Ban02PagoSoles,Ban02PagoDolares  

        
,Ban02TipoDetraccion          
,Ban02TasaDetraccion          
,Ban02ImporteDetraccionSoles,Ban02ImporteDetraccionDolares,          
Ban02TasaRetencion,Ban02ImporteRetencionSoles,Ban02ImporteRetencionDolares,          
Ban02TasaPercepcion,Ban02Imp
ortePercepcionSoles,Ban02ImportePercepcionDolares,           
Ban02NetoSoles,Ban02NetoDolares          
)          
          
          
Select @Ban01Empresa as 'empresa',@ultimoCodigo,      
RIGHT('00000' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT CO26N
UMLOTE)) AS VARCHAR(5)), 5) as 'Correlativo',          
CO26RUC,CO26TIPDOC,CO26NRODOC,          
Convert(decimal(18,2),CO26IMPORTEDETRA),Convert(decimal(9,2),CO26IMPORTEDETRADOL),          
''as 'Detra_Tipo',          
0 as 'Detra_porcentaje',          
0

 as 'Detra_ImpSoles',          
0 as 'Detra_ImpDolares',          
--          
0 as 'RetencionTasa',          
0 as 'RetencionMontoSoles',          
0 as 'RetencionMontoDolares',          
0 as 'PercepcionTasa',          
0 as 'PercepcionSoles',         

 
0 as 'PercepcionDolares',          
Convert(decimal(9,2),CO26IMPORTEDETRA),          
Convert(decimal(9,2),CO26IMPORTEDETRADOL)          
 From CO26PAGODETRACCION detra Inner Join CO05DOCU docu On          
detra.CO26CODEMP = docu.CO05CODEMP and        


detra.CO26RUC = docu.CO05CODCTE and           
detra.CO26TIPDOC = docu.CO05TIPDOC and           
detra.CO26NRODOC = docu.CO05NRODOC          
where           
Detra.CO26CODEMP=@Ban01Empresa and detra.CO26NUMLOTE=@DetraccionLote          
      
if @@ERRO
R  <> 0       
begin      
 set @mensaje = 'Error al registrar detalle detraccion'      
 Goto ManejaError      
end          
--Select *  from CO26PAGODETRACCION where CO26CODEMP='01' and CO26NUMLOTE='200710'          
      
declare @flagComprobante as 

int       
declare @mensajeComprobante as varchar(100)      
exec Spu_Ban_Upd_ComprobantePago @Ban01Empresa,@Ban01Anio,       
@Ban01Mes, @ultimoCodigo, @Ban01Fecha, @numerooperacion, @enlacepago,      
@nombreArchivo,@contenidoArchivo,@flagOperacion, @fl
agComprobante out , @mensajeComprobante out      
      
      
set @flag = 1      
set @mensaje = 'El Pago detraccion se registro exitosamente'      
commit transaction      
return 1      
ManejaError:      
set @flag = -1      
set @mensaje = 'Error al

 registrar pago de detraccion'      
rollback transaction
return -1



go

CREATE Procedure Spu_Ban_Ins_PresupuestoDetraUnitaria      
@Ban01Empresa varchar(2),                          
@Ban01Anio varchar(4),                            
@Ban01Mes varchar(2),                            
@Ban01Descripcion varchar(400),           
                 
@Ban01Fecha varchar(10),                            
@Ban01Estado varchar(2),                            
@Ban01Usuario varchar(15),                            
@Ban01Pc varchar(20),                            
@Ban01FechaRegistro varcha
r(10),                       
@Ban01MedioPago     char(2),              
--    
@Ban01motivopagoCod char(2), -- el 02 es pagar detraccion individual      
-- Datos del detalle    
@Ban02Ruc  varchar(20),    
@Ban02Tipodoc char(2),    
@Ban02NroDoc varchar
(50),    
@Ban02TipoDetraccion varchar(2),          
@Ban02TasaDetraccion decimal(9,2),        
@Ban02ImporteDetraccionSoles decimal(9,2),    
@Ban02ImporteDetraccionDolares decimal(9,2),          
-- Falta Agregar Datos del pago    
@numerooperacion VARC
HAR(10),      --formulario web frontend del metod actualiza comprobante        
@enlacepago VARCHAR(MAX),      --formulario web  frontend del metod actualiza comprobante        
@nombreArchivo VARCHAR(MAX),      -- formulario web frontend del metod actual
iza comprobante        
@contenidoArchivo VARBINARY(MAX),      --formulario web frotend del metod actualiza comprobante        
@flagOperacion CHAR(1),   
    
@flag int output,            
@mensaje varchar(200) output,            
@codigoGenerado varchar
(5) output            
--           
as                      
Begin  
begin transaction  
-- Genera correlativo del presipuesto          
declare @ultimoCodigo     varchar(5)          
select @ultimoCodigo = dbo.ObtenerCorrelativoFormateado(ISNULL(mAX(RIG
HT(Ban01Numero,4)),0)+1) from Ban01PresupuestoPago     
where   Ban01Empresa=@Ban01Empresa    
    
Select @ultimoCodigo          
          
          
-- Insertar Cabecera                  
Insert into Ban01PresupuestoPago(Ban01Numero,Ban01Empresa,Ban01
Anio,Ban01Mes,Ban01motivopagoCod,  
Ban01Descripcion,Ban01Fecha,Ban01Estado,Ban01Usuario,  
Ban01Pc,Ban01FechaRegistro,          
Ban01MedioPago)          
 values (@ultimoCodigo, @Ban01Empresa, @Ban01Anio,  
 @Ban01Mes, @Ban01motivopagoCod,        
 @Ban
01Descripcion, @Ban01Fecha, @Ban01Estado, @Ban01Usuario, @Ban01Pc,               
 @Ban01Fecha, @Ban01MedioPago)                 
  
 If @@ERROR <> 0   
 Begin  
 set @mensaje = 'Erro al registrar cabecera presupuesto'  
 Goto ManejaError  
 End  
  
    
      
          
-- Insertar Detalle           
Insert Into Ban02PresupuestoPagoDetalle(Ban02Empresa,Ban02Numero,Ban02Codigo,    
Ban02Ruc,Ban02Tipodoc,Ban02NroDoc          
,Ban02PagoSoles,Ban02PagoDolares          
,Ban02TipoDetraccion          
,Ban02
TasaDetraccion          
,Ban02ImporteDetraccionSoles,Ban02ImporteDetraccionDolares,          
Ban02NetoSoles,Ban02NetoDolares          
)          
          
Values(@Ban01Empresa,@ultimoCodigo,'00001',    
@Ban02Ruc,@Ban02Tipodoc,@Ban02NroDoc    
,@Ban0
2ImporteDetraccionSoles,@Ban02ImporteDetraccionDolares    
,@Ban02TipoDetraccion          
,@Ban02TasaDetraccion          
,@Ban02ImporteDetraccionSoles,@Ban02ImporteDetraccionDolares    
,@Ban02ImporteDetraccionSoles,@Ban02ImporteDetraccionDolares    
) 
   
  
 if @@ERROR <> 0   
 begin  
  set @mensaje = 'Error al registrar detalle prespuesto'  
  Goto ManejaError  
 end  
    
declare @flagComprobante as int         
declare @mensajeComprobante as varchar(100)        
exec Spu_Ban_Upd_ComprobantePago @
Ban01Empresa,@Ban01Anio,         
@Ban01Mes, @ultimoCodigo, @Ban01Fecha, @numerooperacion, @enlacepago,        
@nombreArchivo,@contenidoArchivo,@flagOperacion, @flagComprobante out , @mensajeComprobante out     
  
set @flag = 1  
set @mensaje = 'El pago
 detraccion individual se registro exitosamente'  
commit transaction  
return 1  
ManejaError:  
set @flag = 1  
set @mensaje = 'Error al registrar detraccion individual'  
  
rollback transaction  
return -1  
  
End

go

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
		   dpp.Ban02Soles, dpp.Ban02Dolares,       
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
		   dpp.[Ban02ImportePercepcionDolares],      
		   dpp.[Ban02NetoSoles],      
		   dpp.[Ban02NetoDolares]  ,    
		   dpp.Ban02FechaEmision,    
		   dpp.Ban02FechaVencimiento  , dpp.Ban02TipoCambio  
		    
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
		   dpp.Ban02Soles, dpp.Ban02Dolares,       
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
		   dpp.[Ban02ImportePercepcionDolares],      
		   dpp.[Ban02NetoSoles],      
		   dpp.[Ban02NetoDolares]  ,    
		   dpp.Ban02FechaEmision,    
		   dpp.Ban02FechaVencimiento  , dpp.Ban02TipoCambio  
		    
		 From Ban02PresupuestoPagoDetalle dpp      
		 left join FAC01_TIPDOC tipodoc      
		 on dpp.Ban02Empresa = tipodoc.FAC01CODEMP      
		 and dpp.Ban02Tipodoc = tipodoc.FAC01COD      
		       
		 where Ban02Empresa = @Empresa       
		 and Ban02Numero = @numeroPresupuesto  
  eND
  
End
go



CREATE procedure Spu_ban_trae_InterbankCabArchivo    
@codigoEmpresa char(2),    
@nombreLote varchar(12),    
@numeroPresupuesto varchar(5)    
    
as    
Begin    
  ---cabecera documento     
  declare @nombreSolicitudLote as varchar(12)    
  set @nombreSolicitudLote = @nombreLote    
  --select @nombreSolicitudLote    
      
  declare @fechadt as datetime = GETDATE()    
  declare @fechatxt as varchar(10) = convert(varchar(10),@fechadt, 103)    
  declare @horatxt as varchar(8) = convert(varchar(10),@fechadt, 108)    
  --dd/MM/yyyy    
  declare @fechaHoraCreacion as varchar(14)    
  select @fechaHoraCreacion = SUBSTRING(@fechatxt, 7,4) + SUBSTRING(@fechatxt, 4,2)+ SUBSTRING(@fechatxt, 1, 2)     
  +SUBSTRING(@horatxt, 1,2) + SUBSTRING(@horatxt, 4,2) + SUBSTRING(@horatxt,7,2)    
  --select @fechaHoraCreacion    
      
  -- nro de registro del presupuesto    
  declare @nroRegistro as varchar(6)    
      
  declare @totalSoles decimal(13,2)    
  declare @totalDolares decimal(13,2)    
      
      
 select      
 @nroRegistro = convert(varchar(6),isnull(COUNT(PP.Ban01Numero),0))   ,     
 @totalSoles  = isnull(sum(bpd.Ban02Soles),0),     
 @totalDolares =  isnull(SUM(bpd.ban02dolares),0)     
 FROM   Ban02PresupuestoPagoDetalle BPD        
    INNER JOIN Ban01PresupuestoPago PP         
     ON BPD.Ban02Numero = PP.Ban01Numero         
       AND BPD.Ban02Empresa = PP.Ban01Empresa            
                    
   Where      
   PP.Ban01Empresa = @codigoEmpresa      
   And PP.Ban01Numero  = @numeroPresupuesto    
       
   --select dbo.ConvertirFormatoAbono(@totalSoles) as 'TotalSoles',  @totalSoles as '@totalSoles',    
   --dbo.ConvertirFormatoAbono(@totalDolares) as 'TotalDolares', @totalDolares as '@totalDolares'    
       
-----------------------------------------------------------------------    
declare @nroRegistrosTexto as varchar(6)    
declare @totalSolesTexto as varchar(15)    
declare @totalDolaresTexto as varchar(15)    
    
 select @nroRegistrosTexto = replicate('0',     
        6-len(@nroRegistro))    
        + rtrim(ltrim(STR(@nroRegistro)))    
  , @totalSolesTexto = dbo.ConvertirFormatoAbono(@totalSoles)     
  , @totalDolaresTexto = dbo.ConvertirFormatoAbono(@totalDolares)    
      
declare @codigoEmpresaInterbank as varchar(4)    
set @codigoEmpresaInterbank  ='0001'    
    
declare @codigoservicioInterbank as varchar(2)    
set @codigoservicioInterbank  = '01'    
---------------------------------------    
  select '01' as codigoRegistro, -- codigoregistro L:2    
   '03' as rubro -- 03:proveedores  L:2    
  ,@codigoEmpresaInterbank as codigoEmpresa, -- L:4    
  @codigoservicioInterbank as 'codigoservicio' , -- L:2    
   TP.Ban01CtaBanCod as 'cuentacargo', -- L:13    
   '001' as 'tipoCuentaCargo', -- 001 cuenta corriente , 002 cuenta ahorro L:3    
   (case TP.ban01moneda    
  when 'S' then '01' else '10' end) --     
  as 'monedaCuentaCargo' ,  -- 01 soles , 10 dolares  L:2    
   @nombreSolicitudLote+ Replicate(' ',12-LEN(@nombreSolicitudLote))    as 'nombreSolicitudLote' -- L:12    
       
   ,@fechaHoraCreacion 'fechahoraCreacion'-- L:14    
   ,'0' as 'tipoProceso' -- 0 : en linea, 1: en diferido     
    ,SUBSTRING(@fechatxt, 7,4) +     
    SUBSTRING(@fechatxt, 4,2)+     
    SUBSTRING(@fechatxt, 1, 2) as 'fechaProceso'   --Si tipo de proceso en línea,     
    --la fecha es del día enviado. Si es Diferido la fecha es futura, no Domingos ni feriados. L: 8    
        
   , @nroRegistrosTexto as 'nroRegistro' -- L:6    
   ,@totalSolesTexto as 'totalSoles' -- L:15    
   ,@totalDolaresTexto as 'totalDolares' -- L:15    
   ,'MC001' as versionMacro    
   from Ban01TipoPago TP           
    LEFT JOIN Ban01CuentaBancaria CB      
     ON TP.Ban01Empresa = CB.Ban01Empresa       
     And TP.Ban01CtaBanBancoCod = CB.Ban01IdCuenta      
     And TP.Ban01CtaBanCod = CB.Ban01IdBanco      
  --select * from Ban01CuentaBancaria    
   where tp.Ban01Empresa = @codigoEmpresa --empresa minera deisi    
   and tp.Ban01IdTipoPago = '04' -- interbank soles    
       
  End 

