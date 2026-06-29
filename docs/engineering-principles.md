# Principios de ingeniería — SOLID y Clean Code en clave Odoo

Estos principios no son genéricos: se aplican dentro del paradigma Active Record de
Odoo. La idea es mantener la lógica en modelos Odoo, con métodos pequeños y puntos de
extensión claros.

## SOLID en Odoo

- **SRP.** Un modelo representa una entidad; un método hace una sola cosa.
- **OCP.** Extiende por `_inherit`, herencia de vistas y hooks, no copiando core.
- **LSP.** Si sobrescribes, respeta contrato y firma; llama a `super()` cuando aplica.
- **ISP.** Prefiere mixins pequeños y cohesivos antes que módulos “todo en uno”.
- **DIP.** Depende de abstracciones de Odoo: `self.env`, `ir.config_parameter`,
  `res.config.settings`, hooks de integración y contexto.

## Clean Code en Odoo

- Métodos pequeños y nombrados.
- DRY, pero sin sobre-abstraer antes de tiempo.
- Early returns para reducir anidación.
- Lógica de negocio en modelos, no en vistas.
- `snake_case` en Python y nombres descriptivos en XML.

## Disciplina agentic

- Verifica primero que el patrón exista en el fuente.
- Si una suposición no se sostiene, corrige el artefacto, no el código a ciegas.
- Evita patrones importados de otros stacks que no aporten valor real en Odoo.

## Manejo de errores

- Usa la excepción correcta: `UserError`, `ValidationError`, `AccessError`,
  `RedirectWarning`.
- No tragues excepciones genéricas.
- La idempotencia debe quedar explícita en integraciones con sistemas externos.

## Logging

- Usa `_logger = logging.getLogger(__name__)`.
- No uses `print`.
- Loguea contexto útil: ids, operación y módulo.

## Anti-patrones

- Repository/DAO sobre el ORM.
- Service Layer artificial para lógica que ya encaja en modelos Odoo.
- DDD formal forzado.
- Inyección de dependencias encima de `self.env`.
- Jerarquías profundas y sobre-abstracción.
