# Setup  Web + Mobile

## O que você fará nesta tarefa?

> **Atenção: Consulte as ISSUES atribuidas a você**

Nesta tarefa, você implementará um sistema de autenticação completo em duas plataformas (Web e Mobile) utilizando Firebase Authentication com Google Sign-In. O objetivo é criar uma aplicação que permita aos usuários fazerem login e logout de forma segura, com integração a uma API backend que valida tokens JWT.

**Principais componentes que serão desenvolvidos:**

1. **Configuração dos Projetos**: Setup inicial dos projetos React (Web) e React Native (Mobile) com todas as dependências necessárias
2. **Firebase Authentication**: Configuração do Firebase Authentication com Google Sign-In em ambas as plataformas
3. **Serviço de API**: Implementação de interceptors HTTP (Axios) para adicionar tokens JWT automaticamente nas requisições
4. **Gerenciamento de Estado**: Criação de AuthContext para gerenciar o estado de autenticação globalmente
5. **Interface do Usuário**: Desenvolvimento de telas/páginas de login, logout e rotas protegidas
6. **Navegação**: Implementação de navegação com rotas protegidas baseadas no estado de autenticação

**Tecnologias utilizadas:**

- **Web**: React, Vite, Firebase SDK, Axios, React Router
- **Mobile**: React Native (Expo), Firebase SDK, Axios, React Navigation, Google Sign-In

**Resultado esperado**: Uma aplicação funcional com autenticação completa, onde os usuários podem fazer login com Google, ter seus tokens validados pelo backend, e acessar rotas protegidas apenas quando autenticados.

## 📁 Estrutura do Projeto

```text
template-autenticacao/
├── react-web/          # Projeto React Web (Vite)
├── react-mobile/       # Projeto React Native (Expo)
├── grading/            # Scripts de autograde
│   ├── run_autograde.ps1
│   └── run_autograde_mobile.ps1
├── results/            # Resultados dos testes (gerados automaticamente)
│   ├── react-web/
│   └── react-mobile/
└── .github/            # Workflow de autograde
    └── workflows/
        └── autograde.yml
```

### Comandos Úteis

**Instalar dependências (raiz):**

```bash
npm ci
```

**Rodar todos os testes (local):**

```bash
npm test --workspaces
```

**Ou executar os scripts dentro das pastas:**

```bash
# React Web
cd react-web && npm ci && npm test

# React Mobile
cd react-mobile && npm ci && npm test
```

**Para mais detalhes sobre testes locais, consulte:** [`testes-locais.md`](./testes-locais.md)

---

## 🎯 Épico 1: Configuração e Setup

### Card 1: Configuração Inicial do Projeto

**Título**: `[Setup] Configuração inicial dos projetos Web e Mobile`

**Descrição**:
Configurar projetos React (Web) e React Native (Mobile), incluindo instalação de dependências, estrutura de pastas e configurações básicas.

**Dependências**:

- Nenhuma (card inicial)

**Bloqueia**:

- Card 2 (Configuração do Firebase)
- Card 3 (Serviço de API e Interceptors)
- Card 5 (AuthContext e Gerenciamento de Estado)
- Card 6 (Interface do Usuário e Navegação)

**Checklist**:

#### Web (React)

- [ ] Criar projeto React (Vite ou Create React App)
- [ ] Instalar dependências: `firebase`, `axios`, `react-router-dom`
- [ ] Configurar estrutura de pastas (`src/config`, `src/services`, `src/context`, `src/pages`, `src/components`)
- [ ] Configurar variáveis de ambiente (`.env`)
- [ ] Configurar ESLint/Prettier (opcional)
- [ ] Testar inicialização do projeto

#### Mobile (React Native)

- [ ] Criar projeto React Native (Expo ou CLI)
- [ ] Instalar dependências: `@react-native-firebase/app`, `@react-native-firebase/auth`, `@react-native-google-signin/google-signin`, `axios`, `@react-native-async-storage/async-storage`, `@react-navigation/native`, `react-native-paper`
- [ ] Configurar estrutura de pastas (`src/config`, `src/services`, `src/context`, `src/screens`, `src/components`)
- [ ] Configurar variáveis de ambiente (`.env` ou `app.json`)
- [ ] Configurar `babel.config.js` se necessário
- [ ] Configurar `app.json` (Expo) ou `android/app/build.gradle` (CLI)
- [ ] Testar inicialização do projeto

**Labels**: `setup`, `dependencies`, `config`, `web`, `mobile`
**Prioridade**: 🔴 Alta
**Estimativa**: 3h (1.5h Web + 1.5h Mobile)

### Card 2: Configuração do Firebase (Web e Mobile)

**Título**: `[Setup] Configurar Firebase Authentication para Web e Mobile`

**Descrição**:
Configurar Firebase Authentication em ambos os projetos, incluindo credenciais, provedores de autenticação e configurações específicas de plataforma.

**Dependências**:

- Card 1 (Configuração Inicial do Projeto)

**Bloqueia**:

- Card 3 (Serviço de API e Interceptors)
- Card 5 (AuthContext e Gerenciamento de Estado)
- Card 6 (Interface do Usuário e Navegação)

**Checklist**:

#### Web (React)

- [ ] Criar projeto no Firebase Console
- [ ] Habilitar Google como provedor de autenticação
- [ ] Obter credenciais do Firebase (API Key, Auth Domain, Project ID, etc.)
- [ ] Criar arquivo `.env` com variáveis de ambiente (`VITE_FIREBASE_API_KEY`, etc.)
- [ ] Criar arquivo `src/config/firebase.js`
- [ ] Configurar `initializeApp()` com credenciais
- [ ] Configurar `initializeAuth()` com persistência
- [ ] Configurar `GoogleAuthProvider` com `prompt: 'select_account'`
- [ ] Exportar `auth`, `googleProvider`, `signInWithPopup`, `onIdTokenChanged`
- [ ] Testar inicialização do Firebase

#### Mobile (React Native)

- [ ] Configurar Firebase para Android:
  - [ ] Baixar `google-services.json` do Firebase Console
  - [ ] Colocar em `android/app/` (CLI) ou raiz do projeto (Expo)
  - [ ] Configurar `app.json` com `googleServicesFile: "./google-services.json"`
  - [ ] Configurar package name no Firebase Console
- [ ] Configurar Firebase para iOS (se aplicável):
  - [ ] Baixar `GoogleService-Info.plist`
  - [ ] Adicionar ao projeto iOS
- [ ] Criar arquivo `src/config/firebase.js`
- [ ] Configurar `initializeApp()` com credenciais
- [ ] Configurar `initializeAuth()` com `getReactNativePersistence`
- [ ] Configurar Google Sign-In:
  - [ ] Obter `webClientId` do Firebase Console
  - [ ] Configurar `GoogleSignin.configure()` com `webClientId`
  - [ ] Implementar função `signInWithGoogle()` usando `@react-native-google-signin/google-signin`
  - [ ] Implementar função `signInWithGoogleToken()` para autenticar no Firebase
- [ ] Exportar funções necessárias (`auth`, `signInWithGoogle`, `signOutUser`, `onIdTokenChanged`)
- [ ] Testar configuração no Android
- [ ] Testar configuração no iOS (se aplicável)

**Labels**: `setup`, `firebase`, `authentication`, `google-signin`, `web`, `mobile`
**Prioridade**: 🔴 Alta
**Estimativa**: 4h (1.5h Web + 2.5h Mobile)

---

## 📚 Referências

- [Aula: Arquitetura de Autenticação Dupla | Firebase + Backend Microserviços](https://uberhub-mentorias.github.io/docusaurus/docs-originais/auth/AULA_FIREBASE_AUTH)
- [4. Plano de Implementação - React Web](https://uberhub-mentorias.github.io/docusaurus/docs-originais/auth/AULA_FIREBASE_AUTH/#43-configura%C3%A7%C3%A3o-do-firebase)
- [5. Plano de Implementação - React Native](https://uberhub-mentorias.github.io/docusaurus/docs-originais/auth/AULA_FIREBASE_AUTH/#53-configura%C3%A7%C3%A3o-do-firebase)
