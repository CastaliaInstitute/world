import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const config = window.CASTALIA_SUPABASE || {};
const statusEl = document.querySelector("[data-auth-status]");
const signInView = document.querySelector("[data-sign-in]");
const authorizedView = document.querySelector("[data-authorized]");
const deniedView = document.querySelector("[data-denied]");
const itineraryView = document.querySelector("[data-itinerary]");
const itineraryList = document.querySelector("[data-itinerary-list]");
const documentsView = document.querySelector("[data-documents]");
const documentList = document.querySelector("[data-document-list]");
const form = document.querySelector("[data-sign-in-form]");
const emailInput = document.querySelector("[data-email]");
const signOutButtons = document.querySelectorAll("[data-sign-out]");

let client;

function setStatus(message, tone = "default") {
  if (!statusEl) return;
  statusEl.textContent = message;
  statusEl.dataset.tone = tone;
}

function show(view) {
  if (signInView) signInView.hidden = view !== "sign-in";
  if (authorizedView) authorizedView.hidden = view !== "authorized";
  if (deniedView) deniedView.hidden = view !== "denied";
}

function configured() {
  return Boolean(
    config.url &&
      config.anonKey &&
      !config.url.includes("YOUR_PROJECT_REF") &&
      !config.anonKey.includes("YOUR_SUPABASE_ANON_KEY"),
  );
}

async function userCanAccessFamily() {
  const { data, error } = await client.rpc("user_has_family_access", {
    requested_family_slug: config.familySlug,
  });

  if (error) {
    throw error;
  }

  return data === true;
}

async function loadDocuments() {
  if (!documentList || !documentsView) return;

  const { data, error } = await client
    .from("family_documents")
    .select("title, description, storage_path, source_commit, updated_at")
    .eq("family_slug", config.familySlug)
    .order("updated_at", { ascending: false });

  if (error) {
    setStatus(`Document index failed: ${error.message}`, "error");
    return;
  }

  documentList.innerHTML = "";

  for (const familyDocument of data || []) {
    const { data: signed, error: signedError } = await client.storage
      .from("family-documents")
      .createSignedUrl(familyDocument.storage_path, 60 * 10);

    if (signedError) {
      setStatus(`Document link failed: ${signedError.message}`, "error");
      continue;
    }

    const item = documentList.appendChild(document.createElement("li"));
    const link = item.appendChild(document.createElement("a"));
    link.href = signed.signedUrl;
    link.textContent = familyDocument.title;
    link.target = "_blank";
    link.rel = "noopener";

    const meta = item.appendChild(document.createElement("small"));
    meta.textContent =
      familyDocument.description ||
      `Published from ${familyDocument.source_commit || "family repository"}.`;
  }

  documentsView.hidden = false;
}

function formatDateRange(startDate, endDate) {
  const start = new Date(`${startDate}T00:00:00`);
  const end = endDate ? new Date(`${endDate}T00:00:00`) : start;
  const formatter = new Intl.DateTimeFormat(undefined, {
    month: "short",
    day: "numeric",
    year: "numeric",
  });

  if (!endDate || startDate === endDate) {
    return formatter.format(start);
  }

  return `${formatter.format(start)} - ${formatter.format(end)}`;
}

async function loadItinerary() {
  if (!itineraryList || !itineraryView) return;

  const { data, error } = await client
    .from("family_itinerary_curriculum")
    .select("destination_name, location, starts_on, ends_on, curriculum_title, subject, activity_count")
    .eq("family_slug", config.familySlug)
    .order("starts_on", { ascending: true });

  if (error) {
    setStatus(`Itinerary failed: ${error.message}`, "error");
    return;
  }

  itineraryList.innerHTML = "";

  for (const stop of data || []) {
    const item = itineraryList.appendChild(document.createElement("li"));
    const title = item.appendChild(document.createElement("strong"));
    title.textContent = stop.destination_name;

    const dates = item.appendChild(document.createElement("span"));
    dates.textContent = formatDateRange(stop.starts_on, stop.ends_on);

    const details = item.appendChild(document.createElement("small"));
    const curriculum = stop.curriculum_title
      ? `${stop.subject || "Curriculum"}: ${stop.curriculum_title}`
      : "Curriculum not planned yet";
    details.textContent = `${stop.location || "Location TBD"} - ${curriculum} (${stop.activity_count || 0} activities)`;
  }

  itineraryView.hidden = false;
}

async function refresh() {
  if (!configured()) {
    show("sign-in");
    setStatus("Supabase is not configured yet. Add the project URL and anon key.", "error");
    return;
  }

  client = createClient(config.url, config.anonKey);
  const { data, error } = await client.auth.getSession();

  if (error) {
    show("sign-in");
    setStatus(error.message, "error");
    return;
  }

  if (!data.session) {
    show("sign-in");
    setStatus("Sign in with the email address approved for this family workspace.");
    return;
  }

  try {
    const allowed = await userCanAccessFamily();
    if (allowed) {
      show("authorized");
      setStatus(`Signed in as ${data.session.user.email}.`);
      await loadItinerary();
      await loadDocuments();
      return;
    }
    show("denied");
    setStatus(`Signed in as ${data.session.user.email}, but this account is not authorized.`, "error");
  } catch (rpcError) {
    show("denied");
    setStatus(`Authorization check failed: ${rpcError.message}`, "error");
  }
}

form?.addEventListener("submit", async (event) => {
  event.preventDefault();
  if (!configured()) {
    setStatus("Supabase is not configured yet.", "error");
    return;
  }

  client ||= createClient(config.url, config.anonKey);
  const submit = form.querySelector("button[type='submit']");
  if (submit) submit.disabled = true;

  const { error } = await client.auth.signInWithOtp({
    email: emailInput.value,
    options: {
      emailRedirectTo: config.redirectTo || window.location.href,
    },
  });

  if (submit) submit.disabled = false;

  if (error) {
    setStatus(error.message, "error");
    return;
  }

  setStatus("Check your email for a sign-in link.");
});

signOutButtons.forEach((button) => {
  button.addEventListener("click", async () => {
    if (client) {
      await client.auth.signOut();
    }
    show("sign-in");
    setStatus("Signed out.");
  });
});

refresh();
