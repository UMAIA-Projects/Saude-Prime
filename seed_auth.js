const fs = require("fs");
const path = require("path");

// Ler o .env manualmente (sem dependencias externas)
function loadEnv() {
  const envPath = path.join(__dirname, ".env");
  if (!fs.existsSync(envPath)) {
    console.error("Ficheiro .env nao encontrado na raiz do projecto.");
    process.exit(1);
  }
  const lines = fs.readFileSync(envPath, "utf8").split("\n");
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const [key, ...rest] = trimmed.split("=");
    if (key && rest.length) {
      process.env[key.trim()] = rest.join("=").trim();
    }
  }
}
loadEnv();

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY  = process.env.SUPABASE_SERVICE_KEY;

if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error("Variaveis em falta no .env:");
  console.error("  SUPABASE_URL=https://XXXXX.supabase.co");
  console.error("  SUPABASE_SERVICE_KEY=eyJ...");
  process.exit(1);
}

const PASSWORD = "12345678";

const USERS = [
  // Medicos
  { id: "11111111-1111-1111-1111-111111111111", email: "medico1@saudeprime.pt",   name: "Dr. Joao Silva"    },
  { id: "11111111-1111-1111-1111-111111111112", email: "medico2@saudeprime.pt",   name: "Dra. Carla Mendes" },
  { id: "11111111-1111-1111-1111-111111111113", email: "medico3@saudeprime.pt",   name: "Dr. Rui Fonseca"   },
  // Pacientes
  { id: "22222222-2222-2222-2222-222222222221", email: "paciente1@saudeprime.pt", name: "Maria Santos"      },
  { id: "22222222-2222-2222-2222-222222222222", email: "paciente2@saudeprime.pt", name: "Antonio Rodrigues" },
  { id: "22222222-2222-2222-2222-222222222223", email: "paciente3@saudeprime.pt", name: "Sofia Pereira"     },
  { id: "22222222-2222-2222-2222-222222222224", email: "paciente4@saudeprime.pt", name: "Carlos Gomes"      },
  { id: "22222222-2222-2222-2222-222222222225", email: "paciente5@saudeprime.pt", name: "Ines Oliveira"     },
  { id: "22222222-2222-2222-2222-222222222226", email: "paciente6@saudeprime.pt", name: "Miguel Costa"      },
  { id: "22222222-2222-2222-2222-222222222227", email: "paciente7@saudeprime.pt", name: "Beatriz Ferreira"  },
  { id: "22222222-2222-2222-2222-222222222228", email: "paciente8@saudeprime.pt", name: "Luis Martins"      },
  { id: "22222222-2222-2222-2222-222222222229", email: "paciente9@saudeprime.pt", name: "Filipa Sousa"      },
  // Staff
  { id: "33333333-3333-3333-3333-333333333333", email: "recepcao@saudeprime.pt",  name: "Ana Ferreira"      },
  { id: "44444444-4444-4444-4444-444444444444", email: "admin@saudeprime.pt",     name: "Admin SaudePrime"  },
  // Equipa adicional
  { id: "55555555-5555-5555-5555-555555555551", email: "ricardo@saudeprime.pt",   name: "Dr. Ricardo"       },
  { id: "55555555-5555-5555-5555-555555555552", email: "rodrigo@saudeprime.pt",   name: "Rodrigo"           },
  { id: "55555555-5555-5555-5555-555555555553", email: "marta@saudeprime.pt",     name: "Marta"             },
  { id: "55555555-5555-5555-5555-555555555554", email: "juliana@saudeprime.pt",   name: "Dra. Juliana"      },
  { id: "55555555-5555-5555-5555-555555555555", email: "felipe@saudeprime.pt",    name: "Felipe"            },
];

async function createUser(user) {
  process.stdout.write(`  ${user.email}... `);

  const res = await fetch(`${SUPABASE_URL}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      "apikey":        SERVICE_KEY,
      "Authorization": `Bearer ${SERVICE_KEY}`,
      "Content-Type":  "application/json",
    },
    body: JSON.stringify({
      id:             user.id,
      email:          user.email,
      password:       PASSWORD,
      email_confirm:  true,
      user_metadata:  { name: user.name },
    }),
  });

  if (res.status === 200 || res.status === 201) {
    console.log("criado");
  } else if (res.status === 422) {
    console.log("ja existe (ok)");
  } else {
    const body = await res.text();
    console.log(`erro HTTP ${res.status}: ${body}`);
    process.exit(1);
  }
}

async function main() {
  console.log("\nA criar utilizadores de teste...\n");
  for (const user of USERS) {
    await createUser(user);
  }
  console.log(`\nPronto! Password de todos: ${PASSWORD}\n`);
  console.log("Medicos:    medico1@saudeprime.pt  medico2@saudeprime.pt  medico3@saudeprime.pt  ricardo@saudeprime.pt  juliana@saudeprime.pt");
  console.log("Pacientes:  paciente1..9@saudeprime.pt  marta@saudeprime.pt");
  console.log("Recepcao:   recepcao@saudeprime.pt  rodrigo@saudeprime.pt");
  console.log("Admin:      admin@saudeprime.pt  felipe@saudeprime.pt\n");
}

main();