# EDI e integraciones con autoridades fiscales — Odoo 18.0 EE

> Estándar de desarrollo para módulos que emiten/transmiten documentos electrónicos
> (CPE, CFDI, FatturaPA, GRE/e-waybill, etc.) e integran con una autoridad fiscal u OSE.
> Hermano de `security.md` y `testing.md`. Es la única fuente de verdad de la lente
> **`odoo-edi-reviewer`** (5º revisor del panel adversarial) y lo lee el
> `odoo-module-developer` al implementar un módulo fiscal. La mecánica del golden-file
> (§8) la valida el `odoo-tests-reviewer` vía [testing.md](testing.md).
>
> **Estándar activo** (origen: estudio l10n_co_dian / l10n_mx_edi / l10n_es_edi_* /
> l10n_in_ewaybill / l10n_it_edi vs base l10n_pe, 2026-06-15). Aplicable a Odoo 18.0 EE.

## 1. Framework de envío: `account.move.send` (no `account.edi.format`)

`account.move.send` (en `account/`) es el **orquestador unificado** de "Enviar e imprimir".
El framework legacy `account.edi.format` (módulo `account_edi`) **se enchufa dentro** de él
(`account_edi/models/account_move_send.py` hace `_inherit = 'account.move.send'`). Por tanto
ambos coexisten en 18.0: el legacy es un mecanismo *bajo* el orquestador, no un mundo aparte.

**Regla — módulos/regímenes EDI NUEVOS:**

- Registran su EDI en `account.move.send` overriding `_get_all_extra_edis()` →
  `{'<key>': {'label': _(...), 'is_applicable': <callback>}}`.
- Implementan `_call_web_service_before_invoice_pdf_render()` (o `_after_`) para render/sign/send.
- Renderizan UBL con un `AbstractModel account.edi.xml.ubl_<x>` (`_inherit=['account.edi.xml.ubl_21']`)
  overriding hooks por-nodo (`_add_*_nodes`/`_get_*_node`, idiom `document_node` dict-tree) y
  `_export_invoice_constraints(move, vals)` como **único** punto de validaciones (dict key→mensaje).
- **NO** crean nuevos `account.edi.format` ni overrides de `_post_invoice_edi`.
- Referencia: `l10n_co_dian/models/account_move_send.py`, `account_edi_xml_ubl_dian.py`.

## 2. Coexistencia y deconflicción (evitar el doble envío)

El riesgo real no es incompatibilidad: es **enviar dos veces el mismo documento** a la autoridad.

**Regla — convivir con una localización legacy en el mismo documento:**

- Cada EDI decide por-movimiento si aplica con su `is_applicable` callback. Gatea el tuyo para
  que dispare solo cuando deba; nunca tengas el `account.edi.format` nativo Y un `extra_edi`
  propio enviando el mismo comprobante.
- **Migración de una localización al framework nuevo** = el patrón Colombia: el módulo nuevo
  `depends` del legacy y `auto_install: ['<legacy>']`, registra su `extra_edi` y deconflicta con
  `is_applicable`. Referencia: `l10n_co_dian/__manifest__.py` (`depends`+`auto_install` de `l10n_co_edi`).

**Regla — EXTENDER una localización nativa que sigue en `account.edi.format`:**

- Usa sus **hooks provider documentados** (p.ej. `selection_add` en el campo provider de
  `res.company` + `_<sign|cancel|get_status>_invoices_<provider>` despachados por `getattr`).
  NO forkees el renderer ni el cliente de transporte. Ese flujo legacy **ya corre por
  `account.move.send`**; extenderlo es correcto hasta que el nativo migre.
- Caso PE (18.0): `l10n_pe_edi` está en `account.edi.format` (`pe_ubl_2_1`); un OSE (Nubefact) se
  añade vía `selection_add` + `_l10n_pe_edi_sign_invoices_<provider>` delegando a
  `_l10n_pe_edi_sign_service_sunat_digiflow_common`. No se crea un `account.edi.format` nuevo.

## 3. Firma digital: reutilizar el módulo `certificate`

- `depends` del addon nativo `certificate`; firmar con `certificate.certificate._sign()` y
  `_get_der_certificate_bytes()`. Cada régimen añade su `scope` vía `selection_add`.
- **NO** reimplementar almacenamiento de llaves ni embeber bytes de certificado en
  `ir.config_parameter` (anti-patrón legacy). Referencia: `l10n_co_dian/models/res_company.py`,
  `l10n_es_edi_tbai/models/certificate.py`.

## 4. Patrón Provider (dispatch)

- `_get_<dominio>_method_map()` (o `_get_providers()` + `_fetch_<x>_<provider>()`) keyed en el
  campo provider de `res.company`; una función por `(provider, operación)`. Referencia:
  `l10n_mx_edi/models/l10n_mx_edi_document.py` `_get_pac_method_map`.

## 5. Durabilidad e idempotencia

- **Commit entre round-trips** con la autoridad, guardado por `self._can_commit()` /
  `not modules.module.current_test`: persistir el estado aceptado tras cada respuesta para que un
  fallo de red posterior no lo pierda, y que los tests nunca hagan commit. Ref:
  `l10n_co_dian/models/account_move_send.py`.
- **Idempotencia de reenvío**: ante un error "documento ya procesado" de la autoridad, re-fetch
  del XML almacenado y verificar identidad (RUC/serie-correlativo + fecha) **antes** de marcar
  aceptado — no reenviar a ciegas ni aceptar un documento que no coincide. Ref:
  `l10n_co_dian/models/l10n_co_dian_document.py`.
- **Lock** del record antes de enviar (traducir `LockError` a `UserError`). Ref:
  `l10n_in_ewaybill/models/l10n_in_ewaybill.py`.

## 6. Modelo de auditoría (una interacción = un record)

- Modelo propio con `move_id`/`picking_id`, `attachment_id` (req+resp como `ir.attachment` con
  `res_field`), `state` (`Selection`), `message_json` (`Json`), `message` (`Html` compute),
  `datetime`, snapshots booleanos del entorno usado (test/prod, certificación), `_order` por
  `datetime DESC`, `_inherit = ['mail.thread']`, y guard `@api.ondelete(at_uninstall=False)` que
  **bloquea** `unlink` de documentos enviados/aceptados (forzar cancelación). Ref:
  `l10n_co_dian/models/l10n_co_dian_document.py`, `l10n_mx_edi.document`, `l10n_in_ewaybill`.

## 7. Seguridad y safety de no-producción

- **`data/neutralize.sql`** (Odoo lo auto-descubre, sin entry en manifest) en TODO módulo que
  habla con la autoridad: fuerza el flag sandbox a `true` y pone `NULL` las credenciales, para
  que una BD clonada/neutralizada no emita a producción. Ref: `l10n_co_dian/data/neutralize.sql`.
- **Credenciales** en `res.company` como `Char` con `groups='base.group_system'`, reflejadas
  como `related` en `res.config.settings` + botón "Probar conexión".
- **Entorno** tri-estado `edi_mode` (demo/test/prod) → URL por mapa (demo = sin llamada real), o
  como mínimo un `test_environment` Boolean `default=True`. Ref: `l10n_it_edi`, `l10n_es_edi_verifactu`.
- **ACL tiered** para modelos de auditoría: lectura `base.group_user`, CRUD grupo funcional
  (`account.group_account_invoice`); **nunca** world-writable. Config/credenciales tras `base.group_system`.

## 8. Tests

- Payload de regulador (XML/JSON) bloqueado por **golden-file**: construir el doc bajo
  `freeze_time(cls.frozen_today)`, llamar al método puro de export, y `assertXmlTreeEqual` contra
  `tests/test_files/<caso>.xml` con `___ignore___` para nodos volátiles (firma, hash, fecha).
- Tags: clases offline `@tagged('post_install_l10n','post_install','-at_install')`; tests contra
  servicio real en `*_external.py` con `('external','-standard')` para excluirlos del run por defecto.
- Mockear la función de transporte (no `requests` directo) con respuestas fijas en `tests/responses/`.
- Ref: `l10n_co_dian/tests/common.py`, `l10n_pe_edi/tests/test_edi_xmls.py`, `l10n_in_ewaybill/tests`.
