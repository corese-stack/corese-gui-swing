package fr.inria.corese.gui.util;

import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import fr.inria.corese.core.util.Property;

/**
 * Utilities for accessing Corese properties on the GUI side, without relying on package-private
 * methods/constructors.
 */
public final class GuiPropertyUtils {

    /** Small container (key,label / path) */
    public static final class Pair {
        private final String key;
        private final String path;

        public Pair(String key, String path) {
            this.key = key;
            this.path = path;
        }

        public String key() {
            return key;
        }

        public String path() {
            return path;
        }
    }

    /* --------------------------------------------------------------------- */
    /* LIST OF PAIRS (GUI_QUERY_LIST, GUI_TEMPLATE_LIST, …) */
    /* --------------------------------------------------------------------- */

    public static List<Pair> getGuiList(Property.Value guiValue) {
        String raw = (String) Property.get(guiValue);
        List<Pair> pairs = new ArrayList<>();

        if (raw == null || raw.isBlank()) {
            return pairs;
        }

        for (String entry : raw.split(";")) {
            String[] parts = entry.split("=", 2);
            if (parts.length == 2) {
                pairs.add(new Pair(parts[0].trim(), expand(parts[1].trim())));
            }
        }
        return pairs;
    }

    /* --------------------------------------------------------------------- */
    /* PATH VALUE (public equivalent of Property.pathValue) */
    /* --------------------------------------------------------------------- */

    public static String pathValue(Property.Value v) {
        String val = Property.stringValue(v);
        return expand(val);
    }

    /* --------------------------------------------------------------------- */
    /* VARIABLE EXPANSION & RELATIVE PATH (“./”) */
    /* --------------------------------------------------------------------- */

    private static final String VAR_CHAR = "$";

    private static String expand(String value) {
        if (value == null) return null;

        // 1) Variables $var:
        Map<String, String> varMap = variableMap();
        for (String var : varMap.keySet()) {
            if (value.startsWith(var)) {
                return value.replaceFirst(var, varMap.get(var));
            }
        }

        // 2) Relative path "./" → resolve it from the application's current working
        // directory
        if (value.startsWith("./")) {
            return Path.of(value).normalize().toAbsolutePath().toString();
        }

        return value;
    }

    /** Rebuilds the map { $var -> value } from the VARIABLE property. */
    private static Map<String, String> variableMap() {
        String raw = Property.stringValue(Property.Value.VARIABLE);
        Map<String, String> map = new HashMap<>();
        if (raw == null) return map;

        for (String entry : raw.split(";")) {
            String[] parts = entry.split("=", 2);
            if (parts.length == 2) {
                String key = parts[0].trim();
                if (!key.startsWith(VAR_CHAR)) key = VAR_CHAR + key;
                map.put(key, parts[1].trim());
            }
        }
        return map;
    }

    /* --------------------------------------------------------------------- */
    private GuiPropertyUtils() {
        /* static-only utility */ }
}
