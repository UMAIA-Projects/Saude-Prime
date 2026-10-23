[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/aMkVOcoC)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=22634200&assignment_repo_type=AssignmentRepo)

# Saúde Prime++ Development Report

Welcome to the documentation pages of **Saúde Prime++**!

---

## Vision Statement

Para pessoas que precisam ou procuram análises e consultas especializadas, a **Saúde Prime++** é uma aplicação de gestão clínica multi-perfil que centraliza o agendamento de consultas, o acesso a documentos clínicos, a fila virtual e a comunicação entre pacientes, médicos, rececionistas e administradores.

> *"Descarregue e atualize já a versão mais recente da sua saúde com a Clínica Médica Saúde Prime++"*

---

## Product Main Features

- **Autenticação e gestão de perfis** - Registo, login, recuperação de password e gestão de permissões por role (Paciente, Médico, Rececionista, Admin)
- **Portal do Paciente** - Agendamento, reagendamento e cancelamento de consultas; histórico clínico; acesso e download de documentos; fila virtual; notificações
- **Portal do Médico** - Gestão de agenda; bloqueio de horários de indisponibilidade; registo de consultas; envio de documentos clínicos; gestão da fila virtual
- **Portal da Receção** - Gestão de pacientes; agendamentos; controlo da fila virtual
- **Portal do Admin** - Gestão de utilizadores e permissões; exportação de relatórios para seguradoras; envio de newsletter
- **Sistema de Fila Virtual** - Senhas por ordem de chegada; chamada do próximo paciente; registo de ausências
- **Transferência de Documentos Clínicos** - Upload e download de PDFs (análises, receitas, faturas) com controlo de acesso por role
- **Notificações automáticas** - Email ao paciente em caso de cancelamento, novo documento disponível ou lembrete de consulta (via Supabase Edge Functions)

---

## Assumptions and Dependencies

- Aplicação cross-platform (Android, iOS e Web) desenvolvida em **Flutter**, com **Supabase** como Backend-as-a-Service (PostgreSQL, Auth, Storage e Edge Functions)
- O controlo de acesso é aplicado ao nível da base de dados via políticas Row-Level Security (RLS), sem servidor de aplicação dedicado
- A clínica possui infraestrutura digital para armazenar e gerir informação clínica
- Cumprimento de princípios de privacidade e proteção de dados (RGPD)
- Possibilidade de integração futura com sistemas externos (laboratórios, seguradoras, plataformas de pagamento)

---

## Team Members

| Nome | Email |
|------|-------|
| Felipe Castilho | A047152@umaia.pt |
| Juliana Moreira | A047188@umaia.pt |
| Marta Moreira | A046756@umaia.pt |
| Ricardo Dias | A047068@umaia.pt |
| Rodrigo Esteves | A048074@umaia.pt |