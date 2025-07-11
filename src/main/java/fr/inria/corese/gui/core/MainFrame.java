package fr.inria.corese.gui.core;

import static fr.inria.corese.core.util.Property.Value.GUI_DEFAULT_QUERY;
import static fr.inria.corese.core.util.Property.Value.GUI_RULE_LIST;
import static fr.inria.corese.core.util.Property.Value.GUI_TITLE;
import static fr.inria.corese.core.util.Property.Value.GUI_TRIPLE_MAX;
import static fr.inria.corese.core.util.Property.Value.LOAD_IN_DEFAULT_GRAPH;
import static fr.inria.corese.core.util.Property.Value.LOAD_QUERY;

import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Desktop;
import java.awt.Image;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.ItemEvent;
import java.awt.event.ItemListener;
import java.awt.event.KeyEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;

import javax.imageio.ImageIO;
import javax.swing.ButtonGroup;
import javax.swing.DefaultListModel;
import javax.swing.JCheckBox;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JTabbedPane;
import javax.swing.KeyStroke;
import javax.swing.event.ChangeEvent;
import javax.swing.event.ChangeListener;
import javax.swing.text.BadLocationException;
import javax.swing.text.Document;
import javax.swing.text.Element;
import javax.swing.text.JTextComponent;
import javax.xml.parsers.ParserConfigurationException;

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.xml.sax.SAXException;

import fr.inria.corese.core.Graph;
import fr.inria.corese.core.kgram.core.Mappings;
import fr.inria.corese.core.kgram.event.Event;
import fr.inria.corese.core.load.Load;
import fr.inria.corese.core.load.LoadException;
import fr.inria.corese.core.load.QueryLoad;
import fr.inria.corese.core.load.result.SPARQLResultParser;
import fr.inria.corese.core.print.CanonicalRdf10Format;
import fr.inria.corese.core.print.ResultFormat;
import fr.inria.corese.core.print.rdfc10.CanonicalRdf10.CanonicalizationException;
import fr.inria.corese.core.print.rdfc10.HashingUtility.HashAlgorithm;
import fr.inria.corese.core.query.QueryProcess;
import fr.inria.corese.core.rule.RuleEngine;
import fr.inria.corese.core.sparql.api.ResultFormatDef;
import fr.inria.corese.core.sparql.datatype.DatatypeMap;
import fr.inria.corese.core.sparql.exceptions.EngineException;
import fr.inria.corese.core.sparql.exceptions.SafetyException;
import fr.inria.corese.core.sparql.triple.parser.Access;
import fr.inria.corese.core.sparql.triple.parser.NSManager;
import fr.inria.corese.core.transform.TemplatePrinter;
import fr.inria.corese.core.transform.Transformer;
import fr.inria.corese.core.util.Property;
import fr.inria.corese.core.workflow.Data;
import fr.inria.corese.core.workflow.SemanticWorkflow;
import fr.inria.corese.core.workflow.WorkflowParser;
import fr.inria.corese.core.workflow.WorkflowProcess;
import fr.inria.corese.gui.editor.ShaclEditor;
import fr.inria.corese.gui.editor.TurtleEditor;
import fr.inria.corese.gui.event.MyEvalListener;
import fr.inria.corese.gui.query.Buffer;
import fr.inria.corese.gui.query.GraphEngine;
import fr.inria.corese.gui.query.MyJPanelQuery;
import fr.inria.corese.gui.util.GuiPropertyUtils;
import fr.inria.corese.gui.util.GuiPropertyUtils.Pair;

/** Main window, with the tab container and menu */
public class MainFrame extends JFrame implements ActionListener {

    /** */
    private static MainFrame singleton;

    private static final long serialVersionUID = 1L;
    private static final int LOAD = 1;
    private static final String TITLE = "Corese 4.6.0 - Inria UCA I3S - 2025-07-07";
    // Declare the tab container
    protected static JTabbedPane conteneurOnglets;
    // Counter for the number of query tabs created
    private ArrayList<Integer> nbreTab = new ArrayList<>();
    private String lCurrentPath = "user/home";
    private String lCurrentProperty = "user/home";

    private String lPath;
    private String fileName = "";
    // Boolean variable to determine Kgram or Corese mode
    private boolean isKgram = true;
    boolean trace = false;
    // For the menu
    private JMenuItem loadRDF;
    private JMenuItem loadProperty;
    private JMenuItem loadSHACL;
    private JMenuItem loadSHACLShape;
    private JMenuItem loadQuery;
    private JMenuItem loadResult;
    private JMenuItem execWorkflow, loadWorkflow, loadRunWorkflow;
    private JMenuItem loadRule;
    private JMenuItem loadStyle;
    private JMenuItem cpTransform;
    private JMenu fileMenuSaveResult;
    private JMenuItem saveQuery;
    private JMenuItem saveResultXml;
    private JMenuItem saveResultJson;
    private JMenuItem saveResultCsv;
    private JMenuItem saveResultTsv;
    private JMenuItem saveResultMarkdown;
    private JMenuItem loadAndRunRule;
    private JMenuItem refresh;
    private JMenuItem exportRDF;
    private JMenuItem exportTurtle;
    private JMenuItem exportTrig;
    private JMenuItem exportJson;
    private JMenuItem exportNt;
    private JMenuItem exportNq;
    private JMenuItem exportOwl;
    private JMenu exportCanonic;
    private JMenuItem saveRDFC_1_0_sha256;
    private JMenuItem saveRDFC_1_1_sha384;
    private JMenuItem copy;
    private JMenuItem cut;
    private JMenuItem paste;
    private JMenuItem duplicate;
    private JMenuItem duplicateFrom;
    private JMenuItem newQuery;
    private JMenuItem runRules, runRulesOpt;
    private JMenuItem reset;
    private ButtonGroup myRadio;
    private JRadioButton kgramBox;
    private JMenuItem apropos;
    private JMenuItem tuto;
    private JMenuItem doc;
    private JMenuItem comment;
    private JMenuItem help;
    private JMenuItem next;
    private JMenuItem complete;
    private JMenuItem forward;
    private JMenuItem map;
    private JMenuItem success;
    private JMenuItem quit;
    // Zoom functionality
    private JMenuItem zoomIn;
    private JMenuItem zoomOut;
    private JMenuItem zoomReset;
    private JMenuItem iselect,
            igraph,
            iconstruct,
            iconstructgraph,
            idescribe_query,
            idescribe_uri,
            iask,
            iserviceLocal,
            iserviceCorese,
            imapcorese,
            ifederate,
            iinsertdata,
            ideleteinsert,
            iturtle,
            in3,
            irdfxml,
            ijson,
            itrig,
            ispin,
            iowl,
            ientailment,
            irule,
            ierror,
            ifunction,
            ical,
            iowlrl;
    private JMenuItem itypecheck, ipredicate, ipredicatepath;
    HashMap<Object, DefQuery> itable;
    private JCheckBox checkBoxQuery;
    private JCheckBox checkBoxRule;
    private JCheckBox checkBoxVerbose;
    private JCheckBox checkBoxLoad;
    private JCheckBox cbrdfs,
            cbowlrl,
            cbclean,
            cbrdfsrl,
            cbowlrltest,
            cbowlrllite,
            cbowlrlext,
            cbtrace,
            cbnamed,
            cbindex;
    private JMenuItem validate;
    // Style corresponding to the graph
    private String defaultStylesheet, saveStylesheet;
    private ArrayList<JCheckBox>
            listCheckbox; // list that stores the JCheckBoxes present on the JPanelListener
    private ArrayList<JMenuItem>
            listJMenuItems; // list that stores the Buttons present on the JPanelListener
    // The 4 types of tabs
    private ArrayList<MyJPanelQuery> monTabOnglet;
    private JPanel plus;
    private MyJPanelQuery current;
    private MyJPanelListener ongletListener;
    private ShaclEditor ongletShacl;
    private TurtleEditor ongletTurtle;
    // To know the selected tab
    protected int selected;
    // Text in the query tab
    private String textQuery;
    private static final String SHACL_SHACL = NSManager.SHACL_SHACL;
    // Default text in the query tab
    private static final String DEFAULT_SELECT_QUERY = "select.rq";
    private static final String DEFAULT_GRAPH_QUERY = "graph.rq";
    private static final String DEFAULT_CONSTRUCT_QUERY = "construct.rq";
    private static final String DEFAULT_ASK_QUERY = "ask.rq";
    private static final String DEFAULT_DESCRIBE_QUERY = "describe.rq";
    private static final String DEFAULT_DESCRIBE_URI = "describe_uri.rq";
    private static final String DEFAULT_SERVICE_CORESE_QUERY = "servicecorese.rq";
    private static final String DEFAULT_INSERT_DATA_QUERY = "insertdata.rq";
    private static final String DEFAULT_DELETE_INSERT_QUERY = "deleteinsert.rq";
    private static final String DEFAULT_ENTAILMENT_QUERY = "entailment.rq";
    private static final String DEFAULT_RULE_QUERY = "rule.rq";
    private static final String DEFAULT_FUN_QUERY = "function.rq";
    private static final String DEFAULT_TEMPLATE_QUERY = "turtle.rq";
    private static final String DEFAULT_RDF_XML_QUERY = "rdfxml.rq";
    private static final String DEFAULT_TRIG_QUERY = "trig.rq";
    private static final String DEFAULT_OWL_QUERY = "owl.rq";
    private static final String DEFAULT_SPIN_QUERY = "spin.rq";
    private String defaultQuery = DEFAULT_SELECT_QUERY;
    private GraphEngine myCorese = null;
    private CaptureOutput myCapturer = null;
    private static final Logger LOGGER = LogManager.getLogger(MainFrame.class.getName());
    private MyEvalListener el;
    Buffer buffer;
    private static final String STYLE = "/style/";
    private static final String QUERY = "/query/";
    private static final String STYLESHEET = "style.txt";
    private static final String TXT = ".txt";
    private static final String RQ = ".rq";
    private static final String URI_CORESE = "http://project.inria.fr/corese";
    private static final String URI_GRAPHSTREAM = "http://graphstream-project.org/";
    int nbTabs = 0;

    // Zoom settings
    private float currentZoomFactor = 1.0f; // Default zoom factor (100%)
    private static final float DEFAULT_ZOOM = 1.0f; // Default zoom level
    private static final float MIN_ZOOM = 0.5f;
    private static final float MAX_ZOOM = 3.0f;
    private static final float ZOOM_STEP = 0.1f;

    Command cmd;

    static {
        // false: load files into named graphs
        // true: load files into kg:default graph
        Load.setDefaultGraphValue(false);
    }

    class DefQuery {

        private String query;
        private String name;

        DefQuery(String n, String q) {
            query = q;
            name = n;
        }

        public String getQuery() {
            return query;
        }

        public void setQuery(String query) {
            this.query = query;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }

    /**
     * Creates the main window, initializes Corese
     *
     * @param aCapturer
     * @param args
     */
    public MainFrame(CaptureOutput aCapturer, String[] args) {
        super();
        Access.setMode(Access.Mode.GUI); // before command
        cmd = new Command(args).init();
        this.setTitle(TITLE);
        this.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        this.setSize(900, 700);
        this.setMinimumSize(this.getSize());
        this.setLocationRelativeTo(null);
        this.setResizable(true);
        try {
            defaultQuery = read(QUERY + DEFAULT_SELECT_QUERY);
        } catch (LoadException ex) {
            LogManager.getLogger(MainFrame.class.getName()).log(Level.ERROR, "", ex);
        } catch (IOException ex) {
            LogManager.getLogger(MainFrame.class.getName()).log(Level.ERROR, "", ex);
        }

        // Initialize Corese
        myCapturer = aCapturer;
        setMyCoreseNewInstance(Graph.RDFS_ENTAILMENT_DEFAULT);

        System.setProperty(
                "org.graphstream.ui.renderer", "org.graphstream.ui.j2dviewer.J2DGraphRenderer");

        // Initialize the menu
        initMenu();

        listCheckbox = new ArrayList<>();
        listJMenuItems = new ArrayList<>();

        // Create and add our tab container to the window
        conteneurOnglets = new JTabbedPane();
        this.getContentPane().add(conteneurOnglets, BorderLayout.CENTER);

        // Create and add the two tabs "Listener" and "+"
        monTabOnglet = new ArrayList<>();
        ongletListener = new MyJPanelListener(this);
        ongletShacl = new ShaclEditor(this);
        ongletTurtle = new TurtleEditor(this);
        plus = new JPanel();
        conteneurOnglets.addTab("System", ongletListener);
        conteneurOnglets.addTab("Shacl editor", ongletShacl);
        conteneurOnglets.addTab("Turtle editor", ongletTurtle);
        conteneurOnglets.addTab("+", plus);

        // By default, the selected tab is "listener"
        conteneurOnglets.setSelectedIndex(0);

        // Applies when a tab selection changes
        conteneurOnglets.addChangeListener(
                new ChangeListener() {
                    @Override
                    public void stateChanged(ChangeEvent changeEvent) {
                        // c is the selected component
                        Component c = conteneurOnglets.getSelectedComponent();

                        // selected is the index of the selected component in the tab container
                        selected = conteneurOnglets.getSelectedIndex();

                        // If the selected tab is a Query tab, it becomes the "current" tab
                        if (c instanceof MyJPanelQuery) {
                            current = (MyJPanelQuery) c;

                            // Some menu options become usable
                            cut.setEnabled(true);
                            copy.setEnabled(true);
                            paste.setEnabled(true);
                            duplicate.setEnabled(true);
                            duplicateFrom.setEnabled(true);
                            comment.setEnabled(true);
                            saveQuery.setEnabled(true);
                            fileMenuSaveResult.setEnabled(true);

                            MyJPanelQuery temp =
                                    (MyJPanelQuery) getConteneurOnglets().getComponentAt(selected);

                            if (isKgram) {
                                temp.getButtonTKgram().setEnabled(true);
                            } else {
                                temp.getButtonTKgram().setEnabled(false);
                            }

                        } // Otherwise, they remain grayed out and unusable
                        else {
                            cut.setEnabled(false);
                            copy.setEnabled(false);
                            paste.setEnabled(false);
                            duplicate.setEnabled(false);
                            duplicateFrom.setEnabled(false);
                            comment.setEnabled(false);
                            saveQuery.setEnabled(false);
                            fileMenuSaveResult.setEnabled(false);
                        }
                        // If the selected tab is the "+", create a new Query tab
                        if (c == plus) {
                            execPlus();
                        }
                    }
                });
        this.setVisible(true);

        addWindowListener(
                new WindowAdapter() {
                    @Override
                    public void windowClosing(WindowEvent e) {
                        System.exit(0);
                    }
                });
        appendMsg("Initialization:\n\n" + myCapturer.getContent() + "\n\n");

        // Fill our list of JCheckBox
        listCheckbox.add(checkBoxLoad);
        listCheckbox.add(checkBoxQuery);
        listCheckbox.add(checkBoxRule);
        listCheckbox.add(checkBoxVerbose);
        for (int i = 0; i < listCheckbox.size(); i++) {
            listCheckbox.get(i).setEnabled(false);
        }

        // Fill our list of Buttons
        listJMenuItems.add(help);
        listJMenuItems.add(map);
        listJMenuItems.add(next);
        listJMenuItems.add(forward);
        listJMenuItems.add(quit);
        listJMenuItems.add(complete);
        listJMenuItems.add(success);
        for (int i = 0; i < listJMenuItems.size(); i++) {
            listJMenuItems.get(i).setEnabled(false);
        }
        process(cmd);

        // Set application icon for all operating systems
        setApplicationIcon();

        // Initialize zoom to make interface more readable by default
        currentZoomFactor = 1.1f; // Slightly bigger than default for better readability
        updateZoom();
        appendMsg(
                "Interface initialisée avec zoom à "
                        + String.format("%.0f", currentZoomFactor * 100)
                        + "%\n");
    }

    public void focusMessagePanel() {
        getConteneurOnglets().setSelectedIndex(0);
    }

    /** Sets the application icon for all operating systems */
    private void setApplicationIcon() {
        try {
            // Load the icon from resources
            Image icon = ImageIO.read(getClass().getResource("/icon/corese-icon.png"));

            // Create multiple sizes for better compatibility
            ArrayList<Image> iconList = new ArrayList<>();

            // Add the original icon
            iconList.add(icon);

            // Add scaled versions for different contexts (16x16, 32x32, 48x48, 64x64,
            // 128x128)
            int[] sizes = {16, 32, 48, 64, 128};
            for (int size : sizes) {
                Image scaledIcon = icon.getScaledInstance(size, size, Image.SCALE_SMOOTH);
                iconList.add(scaledIcon);
            }

            // Set the icon for the main window (works on Windows and Linux)
            setIconImage(icon);

            // Set multiple icon sizes for better system integration
            setIconImages(iconList);

            // For macOS: set the icon in the Dock
            if (System.getProperty("os.name").toLowerCase().contains("mac")) {
                try {
                    if (java.awt.Taskbar.isTaskbarSupported()) {
                        java.awt.Taskbar taskbar = java.awt.Taskbar.getTaskbar();
                        if (taskbar.isSupported(java.awt.Taskbar.Feature.ICON_IMAGE)) {
                            taskbar.setIconImage(icon);
                        }
                    }
                } catch (UnsupportedOperationException | SecurityException e) {
                    // Some systems may not support this or may have security restrictions
                    LOGGER.warn("Unable to set Dock icon on macOS: " + e.getMessage());
                }
            }

            // For Windows: Additional compatibility
            if (System.getProperty("os.name").toLowerCase().contains("windows")) {
                // Windows automatically picks the best size from the icon list
                setIconImages(iconList);
            }

            // For Linux: Additional support for window managers
            if (System.getProperty("os.name").toLowerCase().contains("linux")) {
                // Many Linux window managers support multiple icon sizes
                setIconImages(iconList);
            }

            LOGGER.info("Application icon set successfully for " + System.getProperty("os.name"));

        } catch (IOException | IllegalArgumentException e) {
            LOGGER.error("Unable to load the application icon: " + e.getMessage(), e);
        }
    }

    public MyJPanelQuery execPlus() {
        return execPlus("", defaultQuery);
    }

    public MyJPanelQuery execPlus(String name, String str) {
        // s: default text in the query
        textQuery = str;
        // Create a new Query tab
        return newQuery(str, name);
    }

    void setStyleSheet() {
        try {
            saveStylesheet = read(STYLE + STYLESHEET);
        } catch (LoadException ex) {
            LogManager.getLogger(MainFrame.class.getName()).log(Level.ERROR, "", ex);
        } catch (IOException ex) {
            LogManager.getLogger(MainFrame.class.getName()).log(Level.ERROR, "", ex);
        }
        defaultStylesheet = saveStylesheet;
    }

    /** Displays text in the logs panel */
    public void appendMsg(String msg) {
        Document currentDoc = ongletListener.getTextPaneLogs().getDocument();
        try {
            currentDoc.insertString(currentDoc.getLength(), msg, null);

            // Scroll to the bottom after each text addition
            ongletListener.getScrollPaneLog().revalidate();
            int length = currentDoc.getLength();
            ongletListener.getTextPaneLogs().setCaretPosition(length);
        } catch (Exception innerException) {
            LOGGER.fatal("Output capture problem:", innerException);
        }
    }

    public MainFrame msg(String msg) {
        appendMsg(msg);
        return this;
    }

    /** Creates a Query tab */
    MyJPanelQuery newQuery(String query) {
        return newQuery(query, "");
    }

    public MyJPanelQuery getCurrentQueryPanel() {
        Component cp = conteneurOnglets.getSelectedComponent();
        if (cp instanceof MyJPanelQuery) {
            return (MyJPanelQuery) cp;
        }
        return null;
    }

    // test
    MyJPanelQuery getPreviousQueryPanel2() {
        conteneurOnglets.getComponentCount();
        return null;
    }

    public MyJPanelQuery getLastQueryPanel() {
        return getLastQueryPanel(0);
    }

    /** n=0 : last panel, n=1 : last-1 panel */
    public MyJPanelQuery getLastQueryPanel(int n) {
        int i = 0;
        int last = conteneurOnglets.getComponentCount() - 1;

        for (int j = last; j >= 0; j--) {
            Component cp = conteneurOnglets.getComponent(j);
            if (cp instanceof MyJPanelQuery) {
                MyJPanelQuery jp = (MyJPanelQuery) cp;
                if (i++ == n) {
                    return jp;
                }
            }
        }
        return null;
    }

    /**
     * Last element is "+" at length-1, current query panel at length-2, previous query panel at
     * length-3
     *
     * @return
     */
    public MyJPanelQuery getPreviousQueryPanel() {
        if (conteneurOnglets.getComponents().length >= 3) {
            Component cp =
                    conteneurOnglets.getComponent(conteneurOnglets.getComponents().length - 3);
            if (cp instanceof MyJPanelQuery) {
                return (MyJPanelQuery) cp;
            }
        }
        LOGGER.debug("Previous Query Panel not found");
        for (Component cp : conteneurOnglets.getComponents()) {
            LOGGER.debug("gui: " + cp.getClass().getName());
        }
        return null;
    }

    public Mappings getPreviousMappings() {
        MyJPanelQuery panel = getPreviousQueryPanel();
        LOGGER.debug("gui panel: " + panel);
        if (panel != null) {
            LOGGER.debug("gui mappings: " + panel.getMappings());
            return panel.getMappings();
        }
        return null;
    }

    public MyJPanelQuery newQuery(String query, String name) {
        nbTabs++;
        // Removes the "+" tab, adds a Query tab, then recreates the "+" tab afterwards
        conteneurOnglets.remove(plus);
        MyJPanelQuery temp = new MyJPanelQuery(this, query, name);

        monTabOnglet.add(temp);
        nbreTab.add(nbTabs);
        for (int n = 1; n <= monTabOnglet.size(); n++) {
            conteneurOnglets.add("Query" + (n), temp);
        }
        conteneurOnglets.add("+", plus);

        /**
         * adds the close button. Right after creating the Query tab, there are 5 components in the
         * tab container (Listener, Shacl, turtle, Query, +). We differentiate if this is the 1st
         * tab created or not because adding the close cross to the tab adds a component to the tab
         * container (1 tab = 1 tab component + 1 "close cross" component = 2 components) but this
         * only once (2 tabs = 2 tab components + 1 "close cross" component = 3 components).
         * initTabComponent(0); would apply the close cross to the 1st tab of the container i.e. to
         * "Listener" initTabComponent(conteneurOnglets.getComponentCount()-1); would apply it to
         * the last component of the container i.e. to "+"
         * initTabComponent(conteneurOnglets.getComponentCount()-3); because we need to remove the
         * cross and the "+" tab from the count
         */
        // If this is the 1st Query tab created
        if (conteneurOnglets.getComponentCount() == 5) {
            // We apply the close cross on the 4th component (the tab just
            // created)
            initTabComponent(3);
        } // If there were already some
        else {
            initTabComponent(conteneurOnglets.getComponentCount() - 3);
        }

        // Selects the newly created tab
        conteneurOnglets.setSelectedIndex(conteneurOnglets.getComponentCount() - 3);
        return temp;
    }

    // Menu bar
    private void initMenu() {
        JMenuBar menuBar = new JMenuBar();
        // crée les options du menu et leurs listeners
        loadRDF = new JMenuItem("RDF, RDFS, OWL");
        loadRDF.addActionListener(this);
        loadRDF.setToolTipText("Load an RDF dataset or an RDFS or OWL schema");

        loadProperty = new JMenuItem("Property");
        loadProperty.addActionListener(this);
        loadProperty.setToolTipText("Load Property");

        loadRule = new JMenuItem("Rule");
        loadRule.addActionListener(this);
        loadRule.setToolTipText("Load file with inferencing rules");

        loadAndRunRule = new JMenuItem("Load & Run Rule");
        loadAndRunRule.addActionListener(this);

        loadSHACL = new JMenuItem("SHACL");
        loadSHACL.addActionListener(this);
        loadSHACL.setToolTipText("Load SHACL");

        loadSHACLShape = new JMenuItem("SHACL Shape Validator");
        loadSHACLShape.addActionListener(this);
        loadSHACLShape.setToolTipText("Load SHACL Shape Validator");

        loadQuery = new JMenuItem("Query");
        loadQuery.addActionListener(this);
        loadResult = new JMenuItem("Result");
        loadResult.addActionListener(this);

        loadWorkflow = new JMenuItem("Workflow");
        loadWorkflow.addActionListener(this);

        loadRunWorkflow = new JMenuItem("Load & Run Workflow");
        loadRunWorkflow.addActionListener(this);

        loadStyle = new JMenuItem("Style");
        loadStyle.addActionListener(this);

        refresh = new JMenuItem("Reload");
        refresh.addActionListener(this);

        exportRDF = new JMenuItem("RDF/XML");
        exportRDF.addActionListener(this);
        exportRDF.setToolTipText("Export graph in RDF/XML format");

        exportTurtle = new JMenuItem("Turtle");
        exportTurtle.addActionListener(this);
        exportTurtle.setToolTipText("Export graph in Turtle format");

        exportTrig = new JMenuItem("TriG");
        exportTrig.addActionListener(this);
        exportTrig.setToolTipText("Export graph in TriG format");

        exportJson = new JMenuItem("JsonLD");
        exportJson.addActionListener(this);
        exportJson.setToolTipText("Export graph in JSON format");

        exportNt = new JMenuItem("NTriple");
        exportNt.addActionListener(this);
        exportNt.setToolTipText("Export graph in NTriple format");

        exportNq = new JMenuItem("NQuad");
        exportNq.addActionListener(this);
        exportNq.setToolTipText("Export graph in NQuad format");

        exportOwl = new JMenuItem("OWL");
        exportOwl.addActionListener(this);
        exportOwl.setToolTipText("Export graph in OWL format");

        exportCanonic = new JMenu("Canonic");
        exportCanonic.addActionListener(this);

        saveRDFC_1_0_sha256 = new JMenuItem("RDFC-1.0 (sha256)");
        saveRDFC_1_0_sha256.addActionListener(this);

        saveRDFC_1_1_sha384 = new JMenuItem("RDFC-1.0 (sha384)");
        saveRDFC_1_1_sha384.addActionListener(this);

        execWorkflow = new JMenuItem("Process Workflow");
        execWorkflow.addActionListener(this);

        cpTransform = new JMenuItem("Compile Transformation");
        cpTransform.addActionListener(this);

        saveQuery = new JMenuItem("Save Query");
        saveQuery.addActionListener(this);

        saveResultXml = new JMenuItem("XML");
        saveResultXml.addActionListener(this);

        saveResultJson = new JMenuItem("JSON");
        saveResultJson.addActionListener(this);

        saveResultCsv = new JMenuItem("CSV");
        saveResultCsv.addActionListener(this);

        saveResultTsv = new JMenuItem("TSV");
        saveResultTsv.addActionListener(this);

        saveResultMarkdown = new JMenuItem("Markdown");
        saveResultMarkdown.addActionListener(this);

        itable = new HashMap<>();

        iselect = defItem("Select", DEFAULT_SELECT_QUERY);
        igraph = defItem("Graph", DEFAULT_GRAPH_QUERY);
        iconstruct = defItem("Construct", DEFAULT_CONSTRUCT_QUERY);
        iconstructgraph = defItem("Construct graph", "constructgraph.rq");
        iask = defItem("Ask", DEFAULT_ASK_QUERY);
        idescribe_query = defItem("Describe", DEFAULT_DESCRIBE_QUERY);
        idescribe_uri = defItem("Describe URI", DEFAULT_DESCRIBE_URI);
        iserviceLocal = defItem("Service Local", "servicelocal.rq");
        iserviceCorese = defItem("Service Corese", DEFAULT_SERVICE_CORESE_QUERY);
        imapcorese = defItem("Map", "mapcorese.rq");
        ifederate = defItem("Federate", "federate.rq");
        ifunction = defItem("Function", DEFAULT_FUN_QUERY);
        ical = defItem("Calendar", "cal.rq");

        iinsertdata = defItem("Insert Data", DEFAULT_INSERT_DATA_QUERY);
        ideleteinsert = defItem("Delete Insert", DEFAULT_DELETE_INSERT_QUERY);

        ientailment = defItem("RDFS Entailment", DEFAULT_ENTAILMENT_QUERY);
        irule = defItem("Rule/OWL RL", DEFAULT_RULE_QUERY);
        ierror = defItem("Constraint", "constraint.rq");
        iowlrl = defItem("OWL RL Check", "owlrl.rq");

        iturtle = defItem("Turtle", DEFAULT_TEMPLATE_QUERY);
        in3 = defItem("NTriple", "n3.rq");
        irdfxml = defItem("RDF/XML", DEFAULT_RDF_XML_QUERY);
        ijson = defItem("JSON", "json.rq");
        itrig = defItem("Trig", DEFAULT_TRIG_QUERY);
        ispin = defItem("SPIN", DEFAULT_SPIN_QUERY);
        iowl = defItem("OWL", DEFAULT_OWL_QUERY);

        itypecheck = defItem("Engine", "shacl/typecheck.rq");
        ipredicate = defItem("Predicate", "shacl/predicate.rq");
        ipredicatepath = defItem("Predicate Path", "shacl/predicatepath.rq");

        cut = new JMenuItem("Cut");
        cut.addActionListener(this);
        copy = new JMenuItem("Copy");
        copy.addActionListener(this);
        paste = new JMenuItem("Paste ");
        paste.addActionListener(this);
        duplicate = new JMenuItem("Duplicate Query");
        duplicate.addActionListener(this);
        duplicateFrom = new JMenuItem("Duplicate from selection");
        duplicateFrom.addActionListener(this);
        newQuery = new JMenuItem("New Query");
        newQuery.addActionListener(this);
        runRules = new JMenuItem("Run Rules");
        runRules.addActionListener(this);
        runRulesOpt = new JMenuItem("Run Rules Optimize");
        runRulesOpt.addActionListener(this);
        reset = new JMenuItem("Reset");
        reset.addActionListener(this);
        apropos = new JMenuItem("About Corese");
        apropos.addActionListener(this);
        tuto = new JMenuItem("Online tutorial");
        tuto.addActionListener(this);
        doc = new JMenuItem("Online doc GraphStream");
        doc.addActionListener(this);
        myRadio = new ButtonGroup();
        // coreseBox = new JRadioButton("Corese - SPARQL 1.1");
        // coreseBox.setSelected(true);
        // coreseBox.addActionListener(this);system
        kgramBox = new JRadioButton("Corese.Core.Kgram SPARQL 1.1");
        kgramBox.setSelected(true);
        kgramBox.addActionListener(this);
        comment = new JMenuItem("Comment");
        comment.addActionListener(this);
        help = new JMenuItem("About debug");

        next = new JMenuItem("Next");
        complete = new JMenuItem("Complete");
        forward = new JMenuItem("Forward");
        map = new JMenuItem("Map");
        success = new JMenuItem("Success");
        quit = new JMenuItem("Quit");
        cbtrace = new JCheckBox("Trace");
        cbrdfs = new JCheckBox("RDFS Subset");
        cbowlrlext = new JCheckBox("OWL RL Extended");
        cbowlrllite = new JCheckBox("OWL RL Lite");
        cbowlrl = new JCheckBox("OWL RL");
        cbowlrltest = new JCheckBox("OWL RL Test");
        cbrdfsrl = new JCheckBox("RDFS RL");
        cbindex = new JCheckBox("Graph Index");
        cbclean = new JCheckBox("OWL Clean");

        cbnamed = new JCheckBox("Load Named");

        checkBoxLoad = new JCheckBox("Load");
        checkBoxQuery = new JCheckBox("Query");
        checkBoxRule = new JCheckBox("Rule");
        checkBoxVerbose = new JCheckBox("Verbose");
        validate = new JMenuItem("Validate");

        // Initialize zoom menu items
        zoomIn = new JMenuItem("Zoom In");
        zoomIn.addActionListener(this);
        zoomIn.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_PLUS, ActionEvent.CTRL_MASK));
        zoomIn.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_EQUALS, ActionEvent.CTRL_MASK));

        zoomOut = new JMenuItem("Zoom Out");
        zoomOut.addActionListener(this);
        zoomOut.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_MINUS, ActionEvent.CTRL_MASK));

        zoomReset = new JMenuItem("Reset Zoom");
        zoomReset.addActionListener(this);
        zoomReset.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_0, ActionEvent.CTRL_MASK));

        cut.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_X, ActionEvent.CTRL_MASK));
        copy.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_C, ActionEvent.CTRL_MASK));
        paste.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_V, ActionEvent.CTRL_MASK));
        newQuery.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_N, ActionEvent.CTRL_MASK));
        duplicate.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_D, ActionEvent.CTRL_MASK));
        saveQuery.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, ActionEvent.CTRL_MASK));
        help.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_H, ActionEvent.ALT_MASK));
        next.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_N, ActionEvent.ALT_MASK));
        complete.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_C, ActionEvent.ALT_MASK));
        forward.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_F, ActionEvent.ALT_MASK));
        map.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_M, ActionEvent.ALT_MASK));
        next.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_N, ActionEvent.ALT_MASK));
        success.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, ActionEvent.ALT_MASK));
        quit.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_Q, ActionEvent.ALT_MASK));

        JMenu fileMenu = new JMenu("File");
        JMenu editMenu = new JMenu("Edit");
        JMenu engineMenu = new JMenu("Engine");
        JMenu debugMenu = new JMenu("Debug");
        JMenu queryMenu = new JMenu("Query");
        JMenu userMenu = new JMenu("User Query");
        JMenu templateMenu = new JMenu("Template");
        JMenu displayMenu = new JMenu("Display");
        JMenu shaclMenu = new JMenu("Shacl");
        JMenu eventMenu = new JMenu("Event");
        JMenu explainMenu = new JMenu("Explain");
        JMenu aboutMenu = new JMenu("?");

        JMenu fileMenuLoad = new JMenu("Load");
        JMenu fileMenuSaveGraph = new JMenu("Save Graph");
        fileMenuSaveResult = new JMenu("Save Result");

        // On ajoute tout au menu
        fileMenu.add(fileMenuLoad);
        fileMenuLoad.add(loadRDF);
        fileMenuLoad.add(loadProperty);
        fileMenuLoad.add(loadRule);
        fileMenuLoad.add(loadAndRunRule);
        fileMenuLoad.add(loadSHACL);
        fileMenuLoad.add(loadSHACLShape);
        fileMenuLoad.add(loadQuery);
        fileMenuLoad.add(loadResult);
        fileMenuLoad.add(loadWorkflow);
        fileMenuLoad.add(loadRunWorkflow);
        fileMenuLoad.add(loadStyle);

        fileMenu.add(refresh);

        fileMenu.add(execWorkflow);
        fileMenu.add(cpTransform);

        fileMenu.add(fileMenuSaveGraph);
        fileMenuSaveGraph.add(exportRDF);
        fileMenuSaveGraph.add(exportTurtle);
        fileMenuSaveGraph.add(exportTrig);
        fileMenuSaveGraph.add(exportJson);
        fileMenuSaveGraph.add(exportNt);
        fileMenuSaveGraph.add(exportNq);
        fileMenuSaveGraph.add(exportOwl);
        fileMenuSaveGraph.add(exportCanonic);
        exportCanonic.add(saveRDFC_1_0_sha256);
        exportCanonic.add(saveRDFC_1_1_sha384);

        fileMenu.add(saveQuery);

        fileMenu.add(fileMenuSaveResult);
        fileMenuSaveResult.add(saveResultXml);
        fileMenuSaveResult.add(saveResultJson);
        fileMenuSaveResult.add(saveResultCsv);
        fileMenuSaveResult.add(saveResultTsv);
        fileMenuSaveResult.add(saveResultMarkdown);

        queryMenu.add(iselect);
        queryMenu.add(iconstruct);
        queryMenu.add(iconstructgraph);
        queryMenu.add(idescribe_query);
        queryMenu.add(idescribe_uri);
        queryMenu.add(iask);
        queryMenu.add(igraph);
        queryMenu.add(iserviceLocal);
        queryMenu.add(iserviceCorese);
        queryMenu.add(iinsertdata);
        queryMenu.add(ideleteinsert);

        queryMenu.add(imapcorese);
        queryMenu.add(ifederate);
        queryMenu.add(ifunction);
        queryMenu.add(ical);

        userMenu.add(defItem("Count", "count.rq"));

        for (Pair pair : GuiPropertyUtils.getGuiList(Property.Value.GUI_QUERY_LIST)) {
            userMenu.add(defItemQuery(pair.key(), pair.path()));
        }

        explainMenu.add(ientailment);
        explainMenu.add(irule);
        explainMenu.add(ierror);
        explainMenu.add(iowlrl);

        for (Pair pair : GuiPropertyUtils.getGuiList(Property.Value.GUI_EXPLAIN_LIST)) {
            explainMenu.add(defItemQuery(pair.key(), pair.path()));
        }

        templateMenu.add(iturtle);
        templateMenu.add(in3);
        templateMenu.add(irdfxml);
        templateMenu.add(ijson);
        templateMenu.add(itrig);
        templateMenu.add(ispin);
        templateMenu.add(iowl);

        for (Pair pair : GuiPropertyUtils.getGuiList(Property.Value.GUI_TEMPLATE_LIST)) {
            templateMenu.add(defItemQuery(pair.key(), pair.path()));
        }

        displayMenu.add(defDisplay("Turtle", ResultFormat.format.TURTLE_FORMAT));
        displayMenu.add(defDisplay("Trig", ResultFormat.format.TRIG_FORMAT));
        displayMenu.add(defDisplay("RDF/XML", ResultFormat.format.RDF_XML_FORMAT));
        displayMenu.add(defDisplay("JSON LD", ResultFormat.format.JSONLD_FORMAT));
        displayMenu.add(defDisplay("Index", ResultFormat.format.UNDEF_FORMAT));
        displayMenu.add(defDisplay("Internal", ResultFormat.format.UNDEF_FORMAT));

        // Add zoom functionality to display menu
        displayMenu.addSeparator();
        displayMenu.add(zoomIn);
        displayMenu.add(zoomOut);
        displayMenu.add(zoomReset);

        shaclMenu.add(itypecheck);
        shaclMenu.add(defItem("Fast Engine", "shacl/fastengine.rq"));
        shaclMenu.add(ipredicate);
        shaclMenu.add(ipredicatepath);
        shaclMenu.add(defItem("Constraint Function", "shacl/extension.rq"));
        shaclMenu.add(defItem("Path Function", "shacl/funpath.rq"));
        shaclMenu.add(defItem("Path Linked Data", "shacl/service.rq"));

        eventMenu.add(defItemFunction("SPARQL Query", "event/query.rq"));
        eventMenu.add(defItemFunction("SPARQL Update", "event/update.rq"));
        eventMenu.add(defItemFunction("SHACL", "event/shacl.rq"));
        eventMenu.add(defItemFunction("Rule", "event/rule.rq"));
        eventMenu.add(defItemFunction("Entailment", "event/entailment.rq"));

        eventMenu.add(defItemFunction("Unit", "event/unit.rq"));
        eventMenu.add(defItemFunction("Romain", "event/romain.rq"));
        eventMenu.add(defItemFunction("XML", "event/xml.rq"));
        eventMenu.add(defItemFunction("JSON", "event/json.rq"));

        eventMenu.add(defItemFunction("GUI", "event/gui.rq"));

        editMenu.add(cut);
        editMenu.add(copy);
        editMenu.add(paste);
        editMenu.add(duplicate);
        editMenu.add(duplicateFrom);
        editMenu.add(comment);
        editMenu.add(newQuery);

        engineMenu.add(runRules);
        engineMenu.add(runRulesOpt);
        engineMenu.add(reset);
        engineMenu.add(cbtrace);
        engineMenu.add(cbnamed);

        // entailment
        engineMenu.add(cbrdfs);
        engineMenu.add(cbowlrl);
        engineMenu.add(cbowlrlext);
        engineMenu.add(cbowlrltest);
        engineMenu.add(cbrdfsrl);
        engineMenu.add(cbclean);
        engineMenu.add(cbindex);

        for (Pair pair : GuiPropertyUtils.getGuiList(GUI_RULE_LIST)) {
            engineMenu.add(defineRuleBox(pair.key(), pair.path()));
        }

        // engineMenu.add(cbowlrllite);

        myRadio.add(kgramBox);
        aboutMenu.add(apropos);
        aboutMenu.add(tuto);
        aboutMenu.add(doc);

        aboutMenu.add(help);
        ActionListener lHelpListener =
                (ActionEvent l_Event) -> {
                    set(Event.HELP);
                };
        help.addActionListener(lHelpListener);

        debugMenu.add(next);
        ActionListener lNextListener =
                (ActionEvent l_Event) -> {
                    set(Event.STEP);
                };
        next.addActionListener(lNextListener);

        debugMenu.add(complete);
        ActionListener lSkipListener =
                (ActionEvent l_Event) -> {
                    set(Event.COMPLETE);
                };
        complete.addActionListener(lSkipListener);

        debugMenu.add(forward);
        ActionListener lPlusListener =
                (ActionEvent l_Event) -> {
                    set(Event.FORWARD);
                };
        forward.addActionListener(lPlusListener);

        debugMenu.add(map);
        ActionListener lMapListener =
                (ActionEvent l_Event) -> {
                    set(Event.MAP);
                };
        map.addActionListener(lMapListener);

        debugMenu.add(success);
        ActionListener lSuccessListener =
                (ActionEvent e) -> {
                    set(Event.SUCCESS);
                };
        success.addActionListener(lSuccessListener);

        debugMenu.add(quit);
        ActionListener lQuitListener =
                (ActionEvent l_Event) -> {
                    set(Event.QUIT);
                };
        quit.addActionListener(lQuitListener);

        debugMenu.add(checkBoxLoad);

        cbtrace.setEnabled(true);
        cbtrace.addItemListener(
                (ItemEvent e) -> {
                    trace = cbtrace.isSelected();
                });
        cbtrace.setSelected(false);

        cbrdfs.setEnabled(true);
        cbrdfs.addItemListener(
                (ItemEvent e) -> {
                    setRDFSEntailment(cbrdfs.isSelected());
                });
        // default is true, may be set by property file
        cbrdfs.setSelected(Graph.RDFS_ENTAILMENT_DEFAULT);

        // check box is for load file in named graph
        // Property is for load file in default graph, hence the negation
        cbnamed.setSelected(!Property.getBooleanValue(LOAD_IN_DEFAULT_GRAPH));
        cbnamed.setEnabled(true);
        cbnamed.addItemListener(
                (ItemEvent e) -> {
                    Load.setDefaultGraphValue(!cbnamed.isSelected());
                });

        cbowlrl.setEnabled(true);
        cbowlrl.setSelected(false);
        cbowlrl.addItemListener(
                (ItemEvent e) -> {
                    setOWLRL(cbowlrl.isSelected(), RuleEngine.OWL_RL);
                });

        cbowlrltest.setEnabled(true);
        cbowlrltest.setSelected(false);
        cbowlrltest.addItemListener(
                (ItemEvent e) -> {
                    setOWLRL(cbowlrltest.isSelected(), RuleEngine.OWL_RL_TEST);
                });

        cbclean.setEnabled(true);
        cbclean.setSelected(false);
        cbclean.addItemListener(
                (ItemEvent e) -> {
                    if (cbclean.isSelected()) {
                        cleanOWL();
                    }
                });

        cbindex.setEnabled(true);
        cbindex.setSelected(false);
        cbindex.addItemListener(
                (ItemEvent e) -> {
                    if (cbindex.isSelected()) {
                        graphIndex();
                    }
                });

        cbrdfsrl.setEnabled(true);
        cbrdfsrl.setSelected(false);
        cbrdfsrl.addItemListener(
                (ItemEvent e) -> {
                    setOWLRL(cbrdfsrl.isSelected(), RuleEngine.RDFS_RL);
                });

        cbowlrlext.setEnabled(true);
        cbowlrlext.setSelected(false);
        cbowlrlext.addItemListener(
                (ItemEvent e) -> {
                    // OWL RL + extension: a owl:Restriction -> a owl:Class
                    setOWLRL(cbowlrlext.isSelected(), RuleEngine.OWL_RL_EXT, false);
                    setOWLRL(cbowlrlext.isSelected(), RuleEngine.OWL_RL);
                });

        checkBoxLoad.addItemListener(
                new ItemListener() {
                    @Override
                    public void itemStateChanged(ItemEvent e) {}
                });

        debugMenu.add(checkBoxQuery);
        checkBoxQuery.addItemListener(
                new ItemListener() {
                    @Override
                    public void itemStateChanged(ItemEvent e) {}
                });

        debugMenu.add(checkBoxRule);
        checkBoxRule.addItemListener(
                new ItemListener() {
                    @Override
                    public void itemStateChanged(ItemEvent e) {}
                });

        debugMenu.add(checkBoxVerbose);
        checkBoxVerbose.addItemListener(
                new ItemListener() {
                    @Override
                    public void itemStateChanged(ItemEvent e) {
                        if (checkBoxVerbose.isSelected()) {
                            set(Event.VERBOSE);
                        } else {
                            set(Event.NONVERBOSE);
                        }
                    }
                });

        debugMenu.add(validate);
        ActionListener l_validateListener =
                new ActionListener() {
                    @Override
                    public void actionPerformed(ActionEvent l_Event) {
                        lPath = null;
                        JFileChooser fileChooser = new JFileChooser(getPath());
                        fileChooser.setMultiSelectionEnabled(true);
                        int returnValue = fileChooser.showOpenDialog(null);
                        if (returnValue == JFileChooser.APPROVE_OPTION) {
                            File l_Files[] = fileChooser.getSelectedFiles();
                            for (File f : l_Files) {
                                lPath = f.getAbsolutePath();
                                setPath(f.getParent()); // recupere le dossier parent du
                                // fichier que l'on charge
                            }
                        }
                    }
                };
        validate.addActionListener(l_validateListener);
        validate.setToolTipText("to validate loading of file");

        menuBar.add(fileMenu);
        menuBar.add(editMenu);
        menuBar.add(engineMenu);
        menuBar.add(debugMenu);
        menuBar.add(queryMenu);
        menuBar.add(userMenu);
        menuBar.add(templateMenu);
        menuBar.add(displayMenu);
        menuBar.add(shaclMenu);
        menuBar.add(eventMenu);
        menuBar.add(explainMenu);
        menuBar.add(aboutMenu);

        setJMenuBar(menuBar);

        // S'il n'y a pas encore d'onglet Query ces options sont inutilisables
        if (nbreTab.isEmpty()) {
            cut.setEnabled(false);
            copy.setEnabled(false);
            paste.setEnabled(false);
            duplicate.setEnabled(false);
            duplicateFrom.setEnabled(false);
            comment.setEnabled(false);
            saveQuery.setEnabled(false);
            fileMenuSaveResult.setEnabled(false);
        }
    }

    JCheckBox defineRuleBox(String title, String path) {
        JCheckBox box = new JCheckBox(title);
        box.setEnabled(true);
        box.setSelected(false);
        box.addItemListener(
                new ItemListener() {
                    @Override
                    public void itemStateChanged(ItemEvent e) {
                        runRule(box.isSelected(), path);
                    }
                });
        return box;
    }

    JMenuItem defItem(String name, String q) {
        return defItemBasic(QUERY, name, q);
    }

    JMenuItem defItemFunction(String name, String q) {
        return defItemBasic("/function/", name, q);
    }

    JMenuItem defItemBasic(String root, String name, String q) {
        JMenuItem it = new JMenuItem(name);
        it.addActionListener(this);
        try {
            String str = read(root + q);
            itable.put(it, new DefQuery(q, str));
        } catch (LoadException | IOException ex) {
            LOGGER.error(ex);
        }
        return it;
    }

    JMenuItem defDisplay(String name, ResultFormatDef.format format) {
        JMenuItem it = new JMenuItem(name);
        it.addActionListener(
                (ActionEvent event) -> {
                    getCurrentQueryPanel().getTextArea().setText(displayMenu(name, format));
                });
        return it;
    }

    String displayMenu(String name, ResultFormatDef.format format) {
        if (format.equals(ResultFormat.format.UNDEF_FORMAT)) {
            return displayGraph(name, format);
        } else {
            ResultFormat ft = ResultFormat.create(getGraph(), format).setNbTriple(getTripleMax());
            return ft.toString();
        }
    }

    String displayGraph(String name, ResultFormatDef.format format) {
        if (name.equals("Internal")) {
            DatatypeMap.DISPLAY_AS_TRIPLE = false;
        }
        String str = getGraph().display();
        if (name.equals("Internal")) {
            DatatypeMap.DISPLAY_AS_TRIPLE = true;
        }
        return str;
    }

    Graph getGraph() {
        return getMyCorese().getGraph();
    }

    int getTripleMax() {
        int max = 10000;
        if (Property.intValue(GUI_TRIPLE_MAX) != null) {
            max = Property.intValue(GUI_TRIPLE_MAX);
        }
        LOGGER.info("Display triple number: " + max);
        return max;
    }

    JMenuItem defItemQuery(String name, String path) {
        JMenuItem it = new JMenuItem(name);
        it.addActionListener(this);
        try {
            String str = QueryLoad.create().readProtect(path);
            itable.put(it, new DefQuery(path, str));
        } catch (LoadException ex) {
            LOGGER.error(ex);
        }
        return it;
    }

    private void setOWLRL(boolean selected, int owl) {
        setOWLRL(selected, owl, true);
    }

    private void setOWLRL(boolean selected, int owl, boolean inThread) {
        if (selected) {
            Entailment e = new Entailment(myCorese, inThread);
            e.setOWLRL(owl);
            e.setTrace(trace);
            e.process();
        }
    }

    private void runRule(boolean selected, String path) {
        if (selected) {
            Entailment e = new Entailment(myCorese);
            e.setPath(path);
            e.setTrace(trace);
            e.process();
        }
    }

    void cleanOWL() {
        getMyCorese().cleanOWL();
    }

    void graphIndex() {
        getMyCorese().graphIndex();
    }

    // Actions du menu
    @Override
    public void actionPerformed(ActionEvent e) {
        if (e.getSource() == loadResult) {
            loadResult();
        } else if (e.getSource() == loadQuery) {
            loadQuery();
        } else if (e.getSource() == loadRule) {
            loadRule();
        } else if (e.getSource() == loadRDF || e.getSource() == loadSHACL) {
            loadRDF();
        } else if (e.getSource() == loadProperty) {
            loadProperty();
        } else if (e.getSource() == loadSHACLShape) {
            basicLoad(SHACL_SHACL);
        } else if (e.getSource() == execWorkflow) {
            execWorkflow();
        } else if (e.getSource() == loadWorkflow) {
            loadWorkflow(false);
        } else if (e.getSource() == loadRunWorkflow) {
            loadWorkflow(true);
        } else if (e.getSource() == cpTransform) {
            compile();
        }
        // sauvegarde la requête dans un fichier texte (.txt)
        else if (e.getSource() == saveQuery) {
            saveQuery();
        } else if (e.getSource() == loadStyle) {
            String style = loadText();
            defaultStylesheet = style;
        } // Sauvegarde le résultat sous forme XML dans un fichier texte
        else if (e.getSource() == saveResultXml) {
            saveResult(ResultFormat.format.XML_FORMAT);
        } // Sauvegarde le résultat sous forme JSON dans un fichier texte
        else if (e.getSource() == saveResultJson) {
            saveResult(ResultFormat.format.JSON_FORMAT);
        } // Sauvegarde le résultat sous forme CSV dans un fichier texte
        else if (e.getSource() == saveResultCsv) {
            saveResult(ResultFormat.format.CSV_FORMAT);
        } // Sauvegarde le résultat sous forme TSV dans un fichier texte
        else if (e.getSource() == saveResultTsv) {
            saveResult(ResultFormat.format.TSV_FORMAT);
        } // Sauvegarde le résultat sous forme Markdown dans un fichier texte
        else if (e.getSource() == saveResultMarkdown) {
            saveResult(ResultFormat.format.MARKDOWN_FORMAT);
        } // Exporter le graph au format RDF/XML
        else if (e.getSource() == exportRDF) {
            saveGraph(ResultFormat.format.RDF_XML_FORMAT);
        } // Exporter le graph au format Turle
        else if (e.getSource() == exportTurtle) {
            saveGraph(ResultFormat.format.TURTLE_FORMAT);
        } // Exporter le graph au format TriG
        else if (e.getSource() == exportTrig) {
            saveGraph(ResultFormat.format.TRIG_FORMAT);
        } // Exporter le graph au format Json
        else if (e.getSource() == exportJson) {
            saveGraph(ResultFormat.format.JSON_FORMAT);
        } // Exporter le graph au format NTriple
        else if (e.getSource() == exportNt) {
            saveGraph(ResultFormat.format.NTRIPLES_FORMAT);
        } // Exporter le graph au format NQuad
        else if (e.getSource() == exportNq) {
            saveGraph(ResultFormat.format.NQUADS_FORMAT);
        } // Exporter le graph au format OWL
        else if (e.getSource() == exportOwl) {
            saveGraph(Transformer.OWL);
        } // Exporter le graph au format RDFC-1.0 (sha256)
        else if (e.getSource() == saveRDFC_1_0_sha256) {
            saveGraphCanonic(HashAlgorithm.SHA_256);
        } // Exporter le graph au format RDFC-1.0 (sha384)
        else if (e.getSource() == saveRDFC_1_1_sha384) {
            saveGraphCanonic(HashAlgorithm.SHA_384);
        } // Charge et exécute une règle directement
        else if (e.getSource() == loadAndRunRule) {
            loadRunRule();
        } // Couper, copier, coller
        else if (e.getSource() == cut) {
            if (!nbreTab.isEmpty()) {
                current.getTextPaneQuery().cut();
            }
        } // utilisation de la presse papier pour le copier coller
        else if (e.getSource() == copy) {
            if (!nbreTab.isEmpty()) {
                current.getTextPaneQuery().copy();
            }
        } else if (e.getSource() == paste) {
            if (!nbreTab.isEmpty()) {
                current.getTextPaneQuery().paste();
            }
        } // Dupliquer une requête
        else if (e.getSource() == duplicate) {
            if (!nbreTab.isEmpty()) {
                String toDuplicate;
                toDuplicate = current.getTextPaneQuery().getText();
                textQuery = toDuplicate;
                newQuery(textQuery);
            }
        } // Dupliquer une requête à partir du texte sélectionné
        else if (e.getSource() == duplicateFrom) {
            if (!nbreTab.isEmpty()) {
                String toDuplicate;
                toDuplicate = current.getTextPaneQuery().getSelectedText();
                textQuery = toDuplicate;
                newQuery(textQuery);
            }
        } // Commente une sélection dans la requête
        else if (e.getSource() == comment) {
            if (!nbreTab.isEmpty()) {
                String line;
                String result = "";
                int selectedTextSartPosition = current.getTextPaneQuery().getSelectionStart();
                int selectedTextEndPosition = current.getTextPaneQuery().getSelectionEnd();
                for (int i = 0; i < current.getTextAreaLines().getLineCount() - 1; i++) {
                    try {
                        int lineStartOffset = getLineStartOffset(current.getTextPaneQuery(), i);
                        line =
                                current.getTextPaneQuery()
                                        .getText(
                                                lineStartOffset,
                                                getLineOfOffset(current.getTextPaneQuery(), i)
                                                        - lineStartOffset);

                        if (lineStartOffset >= selectedTextSartPosition
                                && lineStartOffset <= selectedTextEndPosition
                                && !line.startsWith("#")) {
                            // on regarde si la ligne est deja commentée ou non
                            // on commente
                            line = "#" + line;
                        }
                        result += line;
                    } catch (BadLocationException e1) {
                        LOGGER.error(e1);
                    }
                }
                current.getTextPaneQuery().setText(result);
            }
        } // crée un nouvel onglet requête
        else if (e.getSource() == newQuery) {
            textQuery = defaultQuery();
            newQuery(textQuery);
        } // Applique les règles chargées
        else if (e.getSource() == runRules) {
            try {
                runRules(false);
            } catch (EngineException ex) {
                LOGGER.error(ex.getMessage());
            }
        } else if (e.getSource() == runRulesOpt) {
            try {
                runRules(true);
            } catch (EngineException ex) {
                LOGGER.error(ex.getMessage());
            }
        } // Remet tout à zéro
        else if (e.getSource() == reset) {
            reset();
        } // Recharge tous les fichiers déjà chargés
        else if (e.getSource() == refresh) {
            this.resetOwlCheckBox();
            ongletListener.refresh(this);
        } else if (e.getSource() == apropos || e.getSource() == tuto || e.getSource() == doc) {
            String uri = URI_CORESE;
            if (e.getSource() == doc) {
                uri = URI_GRAPHSTREAM;
            }
            browse(uri);
        } else if (e.getSource() == kgramBox) {
            isKgram = true;
            // DatatypeMap.setLiteralAsString(true);
            for (int i = 0; i < monTabOnglet.size(); i++) {
                MyJPanelQuery temp = monTabOnglet.get(i);
                temp.getButtonTKgram().setEnabled(true);
            }
        } // Zoom functionality
        else if (e.getSource() == zoomIn) {
            zoomIn();
        } else if (e.getSource() == zoomOut) {
            zoomOut();
        } else if (e.getSource() == zoomReset) {
            zoomReset();
        } else if (itable.get(e.getSource()) != null) {
            // Button Explain
            DefQuery def = itable.get(e.getSource());
            execPlus(def.getName(), def.getQuery());
        }
    }

    public void browse(String url) {
        if (Desktop.isDesktopSupported()
                && Desktop.getDesktop().isSupported(Desktop.Action.BROWSE)) {
            try {
                Desktop.getDesktop().browse(new URI(url));
            } catch (IOException | URISyntaxException e) {
                LOGGER.error(e);
            }
        }
    }

    void loadRunRule() {
        String lPath = null;
        JFileChooser fileChooser = new JFileChooser(getPath());
        fileChooser.setMultiSelectionEnabled(true);
        int returnValue = fileChooser.showOpenDialog(null);
        if (returnValue == JFileChooser.APPROVE_OPTION) {
            File[] lFiles = fileChooser.getSelectedFiles();
            for (File f : lFiles) {
                lPath = f.getAbsolutePath();
                if (lPath != null) {
                    try {
                        setPath(f.getParent());
                        myCorese.load(lPath);
                        appendMsg("Loading file from path : " + f.getAbsolutePath() + "\n");
                        appendMsg(myCapturer.getContent() + "\ndone.\n\n");
                        // do not record because we do not want that this rule based be reloaded
                        // when we perform Engine/Reload
                        // ongletListener.getModel().addElement(lPath);
                        Date d1 = new Date();
                        boolean b = myCorese.runRuleEngine();
                        Date d2 = new Date();
                        LOGGER.info("Time: " + (d2.getTime() - d1.getTime()) / 1000.0);
                        if (b) {
                            appendMsg(
                                    "\n rules applied... \n"
                                            + myCapturer.getContent()
                                            + "\ndone.\n");
                        }
                    } catch (EngineException | LoadException e1) {
                        LOGGER.error(e1);
                        appendMsg(e1.toString());
                    }
                }
            }
            appendMsg("\nLoading is done\n");
        }
    }

    void saveGraph(ResultFormat.format format) {
        Graph graph = myCorese.getGraph();
        ResultFormat ft = ResultFormat.create(graph);
        ft.setSelectFormat(format);
        ft.setConstructFormat(format);
        save(ft.toString());
    }

    void saveGraph(String format) {
        Graph graph = myCorese.getGraph();
        Transformer transformer = Transformer.create(graph, format);
        try {
            save(transformer.transform());
        } catch (EngineException ex) {
            LOGGER.error(ex);
        }
    }

    /**
     * Save the graph in canonic format with the specified algorithm
     *
     * @param format the format in which the graph will be saved
     */
    void saveGraphCanonic(HashAlgorithm algo) {
        Graph graph = myCorese.getGraph();
        CanonicalRdf10Format transformer = null;

        try {
            transformer = new CanonicalRdf10Format(graph, algo);
        } catch (CanonicalizationException ex) {
            // Create a new alert dialog with the error message and ok button
            String errorMessage = "Unable to canonicalize the RDF data. " + ex.getMessage();
            JOptionPane.showMessageDialog(this, errorMessage, "Error", JOptionPane.ERROR_MESSAGE);
        }

        if (transformer != null) {
            save(transformer.toString());
        }
    }

    /**
     * Save the result of a query in the specified format
     *
     * @param format the format in which the result will be saved (See ResultFormat.java for the
     *     list of formats)
     */
    void saveResult(ResultFormat.format format) {
        ResultFormat ft = ResultFormat.create(current.getMappings(), format);
        save(ft.toString());
    }

    void saveQuery() {
        // Create a JFileChooser
        JFileChooser filechoose = new JFileChooser(getPath());
        // Le bouton pour valider l’enregistrement portera la mention enregistrer
        String approve = "Save";
        int resultatEnregistrer =
                filechoose.showDialog(filechoose, approve); // Pour afficher le JFileChooser…
        // Si l’utilisateur clique sur le bouton enregistrer
        if (resultatEnregistrer == JFileChooser.APPROVE_OPTION) {
            File file = filechoose.getSelectedFile();
            setPath(file.getParent());
            // Récupérer le nom du fichier qu’il a spécifié
            String myFile = file.toString();

            if (!myFile.endsWith(RQ) && !myFile.endsWith(TXT)) {
                myFile = myFile + RQ;
            }

            try (OutputStreamWriter writer =
                    new OutputStreamWriter(new FileOutputStream(myFile), StandardCharsets.UTF_8)) {
                writer.write(current.getTextPaneQuery().getText());
                current.setFileName(file.getName());
                writer.close();
                appendMsg("Writing the file : " + myFile + "\n");
            } catch (IOException er) {
                LOGGER.error(er);
            }
        }
    }

    void reset() {
        ongletListener.getTextPaneLogs().setText("");
        ongletListener.getListLoadedFiles().removeAll();
        ongletListener.getModel().removeAllElements();
        setMyCoreseNewInstance();
        appendMsg("reset... \n" + myCapturer.getContent() + "\ndone.\n");
    }

    void save(String str) {
        JFileChooser filechoose = new JFileChooser(getPath());
        // Le bouton pour valider l’enregistrement portera la mention enregistrer
        String approve = "Save";
        int resultatEnregistrer =
                filechoose.showDialog(filechoose, approve); // Pour afficher le JFileChooser…
        // Si l’utilisateur clique sur le bouton enregistrer
        if (resultatEnregistrer == JFileChooser.APPROVE_OPTION) {
            // Récupérer le nom du fichier qu’il a spécifié
            File f = filechoose.getSelectedFile();
            String myFile = f.toString();
            setPath(f.getParent());
            try (OutputStreamWriter writer =
                    new OutputStreamWriter(new FileOutputStream(myFile), StandardCharsets.UTF_8)) {
                writer.write(str);
                writer.close();
                appendMsg("Writing the file : " + myFile + "\n");
            } catch (IOException ex) {
                java.util.logging.Logger.getLogger(MainFrame.class.getName())
                        .log(java.util.logging.Level.SEVERE, null, ex);
            }
        }
    }

    void write(String str, String path) throws IOException {
        // Create a java.io.FileWriter object with the file name as argument in
        // which to save
        FileWriter lu = new FileWriter(path);
        // Put the stream in buffer (in cache)
        BufferedWriter out = new BufferedWriter(lu);
        // Put the content of the text area in the stream
        out.write(str);
        // Fermer le flux
        out.close();
    }

    void runRules(boolean opt) throws EngineException {
        if (opt) {
            cbrdfs.setSelected(false);
            setRDFSEntailment(false);
        }
        Date d1 = new Date();
        boolean b = myCorese.runRuleEngine(opt, trace);
        Date d2 = new Date();
        if (b) {
            appendMsg("\nrules applied... \n" + myCapturer.getContent() + "\ndone.\n");
            appendMsg("time: " + (d2.getTime() - d1.getTime()) / (1000.0));
        }
    }

    String defaultQuery() {
        return defaultQuery;
    }

    public static int getLineStartOffset(final JTextComponent textComponent, final int line)
            throws BadLocationException {
        final Document doc = textComponent.getDocument();
        final int lineCount = doc.getDefaultRootElement().getElementCount();
        if (line < 0) {
            throw new BadLocationException("Negative line", -1);
        } else if (line > lineCount) {
            throw new BadLocationException("No such line", doc.getLength() + 1);
        } else {
            Element map = doc.getDefaultRootElement();
            Element lineElem = map.getElement(line);
            return lineElem.getStartOffset();
        }
    }

    public int getLineOfOffset(final JTextComponent textComponent, final int line)
            throws BadLocationException {
        final Document doc = textComponent.getDocument();
        final int lineCount = doc.getDefaultRootElement().getElementCount();
        if (line < 0) {
            throw new BadLocationException("Negative line", -1);
        } else if (line > lineCount) {
            throw new BadLocationException("No such line", doc.getLength() + 1);
        } else {
            Element map = doc.getDefaultRootElement();
            Element lineElem = map.getElement(line);
            return lineElem.getEndOffset();
        }
    }

    // Pour la croix fermante sur les onglets
    private void initTabComponent(int i) {
        conteneurOnglets.setTabComponentAt(i, new ButtonTabComponent(conteneurOnglets, this));
    }

    /**
     * Allows retrieving the file extension as a String
     *
     * @param o
     * @return
     */
    public String extension(Object o) {
        String extension = null;
        String s = String.valueOf(o);
        int i = s.lastIndexOf('.'); // récupére l'index a partir duquel il faut couper

        if (i > 0 && i < s.length() - 1) {
            extension = s.substring(i + 1).toLowerCase(); // on récupére l'extension
        }
        return extension; // on retourne le résultat
    }

    void display() {
        for (int i = 0; i < getOngletListener().getModel().getSize(); i++) {
            LOGGER.info("GUI: " + ongletListener.getModel().get(i).toString());
        }
    }

    void loadRDF() {
        loadDataset();
    }

    void loadProperty() {
        JFileChooser fileChooser = new JFileChooser(getProperty());
        File selectedFile;
        int returnValue = fileChooser.showOpenDialog(null);
        if (returnValue == JFileChooser.APPROVE_OPTION) {
            selectedFile = fileChooser.getSelectedFile();
            setProperty(selectedFile.getParent());
            init(selectedFile.getAbsolutePath());
        }
    }

    void init(String path) {
        try {
            LOGGER.info("Load Property File: " + path);
            Property.load(path);
        } catch (IOException ex) {
            LOGGER.error(ex);
        }
    }

    void initProperty() {
        if (Property.stringValue(LOAD_QUERY) != null) {
            initLoadQuery(GuiPropertyUtils.pathValue(LOAD_QUERY));
        }
        if (Property.stringValue(GUI_TITLE) != null) {
            setTitle(Property.stringValue(GUI_TITLE));
        }
        if (Property.stringValue(GUI_DEFAULT_QUERY) != null) {
            try {
                defaultQuery =
                        QueryLoad.create().readWE(GuiPropertyUtils.pathValue(GUI_DEFAULT_QUERY));
            } catch (LoadException ex) {
                LOGGER.error(ex);
            }
        }
    }

    void loadDataset() {
        Filter FilterRDF = new Filter("RDF", "rdf", "ttl", "trig", "jsonld", "html");
        Filter FilterRDFS = new Filter("RDFS/OWL", "rdfs", "owl", "ttl");
        Filter FilterOWL = new Filter("OWL", "owl");
        Filter FilterDS = new Filter("Dataset", "rdf", "rdfs", "owl", "ttl", "html");
        load(FilterRDF, FilterRDFS, FilterOWL, FilterDS);
    }

    void execWorkflow() {
        Filter FilterRDF = new Filter("Workflow", "ttl", "sw");
        load(FilterRDF, true, true, false);
    }

    void loadWorkflow(boolean run) {
        Filter FilterRDF = new Filter("Workflow", "ttl", "sw");
        load(FilterRDF, true, false, run);
    }

    /** Charge un fichier dans CORESE */
    void load(Filter... filter) {
        load(false, false, false, filter);
    }

    /**
     * wf: load a Workflow exec: run Workflow using std Worklow engine run: set the queries in query
     * panels an run the queries in the GUI
     */
    public void load(Filter filter, boolean wf, boolean exec, boolean run) {
        load(wf, exec, run, filter);
    }

    void load(boolean wf, boolean exec, boolean run, Filter... filter) {
        controler(LOAD);
        lPath = null;
        JFileChooser fileChooser = new JFileChooser(getPath());
        fileChooser.setMultiSelectionEnabled(true);
        for (Filter f : filter) {
            fileChooser.addChoosableFileFilter(f);
        }
        int returnValue = fileChooser.showOpenDialog(null);
        if (returnValue == JFileChooser.APPROVE_OPTION) {
            File[] lFiles = fileChooser.getSelectedFiles();

            DefaultListModel<String> model = getOngletListener().getModel();
            for (File f : lFiles) {
                lPath = f.getAbsolutePath();
                if (lPath == null) {
                    continue;
                }

                setPath(f.getParent());

                if (!model.contains(lPath) && !wf) {
                    model.addElement(lPath);
                }

                if (extension(lPath) == null) {
                    appendMsg("Error: No extension for file: " + lPath + "\n");
                    appendMsg(
                            "Please select a file with an extension (e.g: .ttl, .rdf, .trig, .jsonld, .html, ...)\n");
                    appendMsg("Load is aborted\n");
                    return;
                }

                appendMsg("Loading " + extension(lPath) + " File from path : " + lPath + "\n");
                if (wf) {
                    if (exec) {
                        execWF(lPath);
                    } else {
                        loadWF(lPath, run);
                    }
                } else {
                    load(lPath);
                }
                appendMsg("\nLoading is done\n");
            }
        }
    }

    void basicLoad(String path) {
        DefaultListModel<String> model = getOngletListener().getModel();
        if (!model.contains(path)) {
            model.addElement(path);
        }
        appendMsg("Loading " + path + "\n");
        load(path);
        appendMsg("Load done\n");
    }

    void execWF(String path) {
        execWF(path, true);
    }

    void execWF(String path, boolean reset) {
        if (reset) {
            reset();
        }
        WorkflowParser parser = new WorkflowParser();
        // parser.setDebug(true);
        try {
            Date d1 = new Date();
            parser.parse(path);
            SemanticWorkflow wp = parser.getWorkflowProcess();
            // wp.setDebug(true);
            Data res = wp.process(new Data(myCorese.getGraph()));
            Date d2 = new Date();
            System.out.println("time: " + (d2.getTime() - d1.getTime()) / (1000.0));
            appendMsg(res.toString() + "\n");
            appendMsg("time: " + (d2.getTime() - d1.getTime()) / (1000.0) + "\n");
        } catch (LoadException ex) {
            LOGGER.error(ex);
            appendMsg(ex.toString());
        } catch (EngineException ex) {
            LOGGER.error(ex);
            appendMsg(ex.toString());
        }
    }

    void loadWF(String path, boolean run) {
        WorkflowParser parser = new WorkflowParser();
        try {
            parser.parse(path);
            SemanticWorkflow wp = parser.getWorkflowProcess();
            defQuery(wp, run);
        } catch (LoadException ex) {
            LOGGER.error(ex);
            appendMsg(ex.toString());
        } catch (SafetyException ex) {
            LOGGER.error(ex);
            appendMsg(ex.toString());
        }
    }

    void defQuery(WorkflowProcess wp, boolean run) {
        if (wp.getProcessList() != null) {
            for (WorkflowProcess wf : wp.getProcessList()) {
                if (wf.isQuery()) {
                    defQuery(wf.getQueryProcess().getQuery(), wf.getPath(), run);
                } else {
                    defQuery(wf, run);
                }
            }
        }
    }

    String selectPath() {
        return selectPath(null);
    }

    String selectPath(String title, String... ext) {
        lPath = null;
        JFileChooser fileChooser = new JFileChooser(getPath());

        if (ext != null && ext.length > 0) {
            Filter filter = new Filter(title, ext);
            fileChooser.addChoosableFileFilter(filter);
        }

        fileChooser.setMultiSelectionEnabled(true);
        fileChooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        int returnValue = fileChooser.showOpenDialog(null);

        if (returnValue == JFileChooser.APPROVE_OPTION) {
            File l_Files[] = fileChooser.getSelectedFiles();

            for (File f : l_Files) {
                lPath = f.getAbsolutePath();
                setPath(f.getParent());
                return lPath;
            }
        }
        return null;
    }

    /** Compile a transformation */
    public void compile() {
        lPath = null;
        JFileChooser fileChooser = new JFileChooser(getPath());
        fileChooser.setMultiSelectionEnabled(true);
        fileChooser.setFileSelectionMode(JFileChooser.FILES_AND_DIRECTORIES);
        int returnValue = fileChooser.showOpenDialog(null);
        if (returnValue == JFileChooser.APPROVE_OPTION) {
            File l_Files[] = fileChooser.getSelectedFiles();

            for (File f : l_Files) {
                lPath = f.getAbsolutePath();
                setPath(f.getParent());
                if (lPath != null) {
                    appendMsg("Compile " + lPath + "\n");
                    compile(lPath);
                }
            }
        }
    }

    void compile(String path) {
        TemplatePrinter p = TemplatePrinter.create(path);
        try {
            StringBuilder sb = p.process();
            if (current != null) {
                current.getTextAreaXMLResult().setText(sb.toString());
            }
            save(sb.toString());

        } catch (IOException ex) {
            LogManager.getLogger(MainFrame.class.getName()).log(Level.ERROR, "", ex);
        } catch (LoadException ex) {
            LogManager.getLogger(MainFrame.class.getName()).log(Level.ERROR, "", ex);
        }
    }

    void controler(int event) {
        switch (event) {
            case LOAD:
                this.resetOwlCheckBox();
                // @todo: user rule check box
                break;
        }
    }

    private void resetOwlCheckBox() {
        cbowlrllite.setSelected(false);

        cbowlrl.setSelected(false);
        cbowlrlext.setSelected(false);
        cbowlrltest.setSelected(false);
    }

    public void load(String fichier) {
        controler(LOAD);
        try {
            Date d1 = new Date();
            myCorese.load(fichier);
            Date d2 = new Date();
            appendMsg(myCapturer.getContent());
            LOGGER.info("Load time: " + (d2.getTime() - d1.getTime()) / 1000.0);
        } catch (EngineException | LoadException e) {
            appendMsg(e.toString());
            e.printStackTrace();
        }
    }

    /** Crée un nouvel onglet requête avec le texte contenu dans un fichier */
    public String loadText() {
        return loadText(null);
    }

    public String loadText(String title, String... ext) {
        String str = "";
        JFileChooser fileChooser = new JFileChooser(getPath());

        if (ext != null && ext.length > 0) {
            Filter filter = new Filter(title, ext);
            fileChooser.addChoosableFileFilter(filter);
        }

        File selectedFile;
        int returnValue = fileChooser.showOpenDialog(null);
        if (returnValue == JFileChooser.APPROVE_OPTION) {
            // Voici le fichier qu'on a selectionné
            selectedFile = fileChooser.getSelectedFile();
            setFileName(selectedFile.getName());
            setPath(selectedFile.getParent());
            FileInputStream fis = null;
            try {
                fis = new FileInputStream(selectedFile);
                int n;
                while ((n = fis.available()) > 0) {
                    byte[] b = new byte[n];
                    // On lit le fichier
                    int result = fis.read(b);
                    if (result == -1) {
                        break;
                    }
                    // On remplit un string avec ce qu'il y a dans le fichier, "s" est ce qu'on va
                    // mettre dans la textArea de la requête
                    str = new String(b);
                    appendMsg("Loading file from path: " + selectedFile + "\n");
                }
                fis.close();
            } catch (IOException ex) {
                LOGGER.error(ex);
            } finally {
                if (fis != null) {
                    try {
                        fis.close();
                    } catch (IOException ex) {
                    }
                }
            }
        }
        appendMsg("\nLoading is done\n");
        return str;
    }

    public void loadQuery() {
        textQuery = loadText("Query", "rq");
        newQuery(textQuery, getFileName());
    }

    void loadResult() {
        try {
            loadResultWE();
        } catch (ParserConfigurationException | SAXException | IOException ex) {
            LOGGER.error(ex.getMessage());
        }
    }

    void loadResultWE() throws ParserConfigurationException, SAXException, IOException {
        String path = selectPath("Load Query Result", ".xml");
        SPARQLResultParser parser = new SPARQLResultParser();
        Mappings map = parser.parse(path);
        MyJPanelQuery panel = execPlus(path, "");
        panel.display(map);
    }

    void defQuery(String text, String name, boolean run) {
        textQuery = text;
        MyJPanelQuery panel = newQuery(textQuery, name);
        if (run) {
            panel.exec(this, text);
        }
    }

    /** Charge un fichier Rule dans CORESE */
    public void loadRule() {
        Filter FilterRUL = new Filter("Rule", "rul", "brul");
        load(FilterRUL);
    }

    public void loadRule(String fichier) {
        try {
            myCorese.load(fichier);
            appendMsg(myCapturer.getContent() + "\ndone.\n\n");
        } catch (EngineException | LoadException e) {
            appendMsg(e.toString());
            e.printStackTrace();
        }
    }

    public void loadRDF(String fichier) {
        try {
            myCorese.load(fichier);
            appendMsg(myCapturer.getContent() + "\ndone.\n\n");
        } catch (EngineException e) {
            appendMsg(e.toString());
            e.printStackTrace();
        } catch (LoadException e) {
            appendMsg(e.toString());
            e.printStackTrace();
        }
    }

    // Getteurs et setteurs utiles
    // donne l'onglet sélectionné
    public int getSelected() {
        return selected;
    }

    // Accède au contenu de du textArea de l'onglet query
    public String getTextQuery() {
        return textQuery;
    }

    // Accède au conteneur d'onglets de la fenêtre principale
    public JTabbedPane getConteneurOnglets() {
        return conteneurOnglets;
    }

    public MyJPanelListener getOngletlistener() {
        return ongletListener;
    }

    public GraphEngine getMyCorese() {
        return myCorese;
    }

    // Réinitialise Corese
    public void setMyCoreseNewInstance() {
        setMyCoreseNewInstance(cbrdfs.isSelected());
    }

    void setMyCoreseNewInstance(boolean rdfs) {
        if (myCorese != null) {
            myCorese.finish();
        }
        myCorese = GraphEngine.create(rdfs);
        // execute options and -init property
        myCorese.init(cmd);
    }

    // at the end of gui creation
    void process(Command cmd) {
        String path = cmd.get(Command.WORKFLOW);
        if (path != null) {
            execWF(path, false);
        }
        try {
            init();
        } catch (EngineException ex) {
            java.util.logging.Logger.getLogger(MainFrame.class.getName())
                    .log(java.util.logging.Level.SEVERE, null, ex);
        }

        if (cmd.getQuery() != null) {
            initLoadQuery(cmd.getQuery());
        }
        initProperty();
    }

    void initLoadQuery(String path) {
        if (path != null) {
            QueryLoad ql = QueryLoad.create();
            String query;
            try {
                query = ql.readWE(path);
                File f = new File(path);
                setPath(f.getParent());
                defQuery(query, path, false);
            } catch (LoadException ex) {
                LOGGER.error(ex.getMessage());
            }
        }
    }

    void init() throws EngineException {
        QueryProcess exec = QueryProcess.create(Graph.create());
        exec.imports(QueryProcess.SHACL);
    }

    void setRDFSEntailment(boolean b) {
        Graph g = myCorese.getGraph();
        g.setRDFSEntailment(b);
    }

    public Logger getLogger() {
        return LOGGER;
    }

    public String readQuery(String name) throws LoadException, IOException {
        return read(QUERY + name);
    }

    String read(String name) throws LoadException, IOException {
        InputStream stream = getClass().getResourceAsStream(name);
        if (stream == null) {
            throw new IOException(name);
        }

        BufferedReader read = new BufferedReader(new InputStreamReader(stream));
        StringBuilder sb = new StringBuilder();
        String str = null;
        String NL = System.getProperty("line.separator");

        while (true) {
            str = read.readLine();
            if (str == null) {
                break;
            } else {
                sb.append(str);
                sb.append(NL);
            }
        }

        stream.close();
        return sb.toString();
    }

    public String getDefaultStylesheet() {
        return defaultStylesheet;
    }

    public String getSaveStylesheet() {
        return saveStylesheet;
    }

    public MyJPanelListener getOngletListener() {
        return ongletListener;
    }

    public void setOngletListener(MyJPanelListener ongletListener) {
        this.ongletListener = ongletListener;
    }

    public CaptureOutput getMyCapturer() {
        return myCapturer;
    }

    public ArrayList<JCheckBox> getListCheckbox() {
        return listCheckbox;
    }

    public void setListCheckbox(ArrayList<JCheckBox> listCheckbox) {
        this.listCheckbox = listCheckbox;
    }

    public ArrayList<JMenuItem> getListJMenuItems() {
        return listJMenuItems;
    }

    public void setListJMenuItems(ArrayList<JMenuItem> listJMenuItems) {
        this.listJMenuItems = listJMenuItems;
    }

    public boolean isKgram() {
        return isKgram;
    }

    public void setKgram(boolean isKgram) {
        this.isKgram = isKgram;
    }

    public MyJPanelQuery getPanel() {
        return current;
    }

    MyEvalListener getEvalListener() {
        return el;
    }

    public void setEvalListener(MyEvalListener el) {
        this.el = el;
    }

    public void setPath(String path) {
        this.lCurrentPath = path;
    }

    public String getPath() {
        return lCurrentPath;
    }

    public void setProperty(String path) {
        this.lCurrentProperty = path;
    }

    public String getProperty() {
        return lCurrentProperty;
    }

    /** For interacting with listener */
    public void setBuffer(Buffer b) {
        buffer = b;
    }

    void set(int event) {
        if (buffer != null) {
            buffer.set(event);
        }
    }

    /**
     * @return the fileName
     */
    public String getFileName() {
        return fileName;
    }

    /**
     * @param fileName the fileName to set
     */
    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public static void main(String[] p_args) {
        CaptureOutput aCapturer = new CaptureOutput();
        MainFrame coreseFrame = new MainFrame(aCapturer, p_args);
        coreseFrame.setStyleSheet();
        coreseFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        MyJPanelListener.listLoadedFiles.setCellRenderer(new MyCellRenderer());
        setSingleton(coreseFrame);
    }

    public void show(String text) {
        getPanel().display(text);
    }

    public static void display(String text) {
        if (getSingleton() != null) {
            getSingleton().appendMsg(text);
            getSingleton().appendMsg("\n");
        }
    }

    public static void newline() {
        if (getSingleton() != null) {
            getSingleton().appendMsg("\n");
        }
    }

    public static MainFrame getSingleton() {
        return singleton;
    }

    public static void setSingleton(MainFrame aSingleton) {
        singleton = aSingleton;
    }

    /** Zoom in the interface */
    private void zoomIn() {
        if (currentZoomFactor < MAX_ZOOM) {
            currentZoomFactor += ZOOM_STEP;
            // Round to avoid floating point precision issues
            currentZoomFactor = Math.round(currentZoomFactor * 10f) / 10f;
            updateZoom();
            appendMsg("Zoom augmenté à " + String.format("%.0f", currentZoomFactor * 100) + "%\n");
        } else {
            appendMsg("Zoom maximum atteint (" + String.format("%.0f", MAX_ZOOM * 100) + "%)\n");
        }
    }

    /** Zoom out the interface */
    private void zoomOut() {
        if (currentZoomFactor > MIN_ZOOM) {
            currentZoomFactor -= ZOOM_STEP;
            // Round to avoid floating point precision issues
            currentZoomFactor = Math.round(currentZoomFactor * 10f) / 10f;
            updateZoom();
            appendMsg("Zoom réduit à " + String.format("%.0f", currentZoomFactor * 100) + "%\n");
        } else {
            appendMsg("Zoom minimum atteint (" + String.format("%.0f", MIN_ZOOM * 100) + "%)\n");
        }
    }

    /** Reset zoom to default level */
    private void zoomReset() {
        currentZoomFactor = DEFAULT_ZOOM; // Reset to default zoom
        updateZoom();
        appendMsg("Zoom remis à " + String.format("%.0f", currentZoomFactor * 100) + "%\n");
    }

    /** Update the zoom level of all UI components */
    private void updateZoom() {
        // Get a base font size (12pt is a common default)
        int baseFontSize = 12;

        // Calculate new font size based on zoom factor
        int newSize = Math.round(baseFontSize * currentZoomFactor);

        // Ensure minimum readable size
        newSize = Math.max(newSize, 8);

        // Create the zoomed font
        java.awt.Font zoomedFont =
                new java.awt.Font(java.awt.Font.SANS_SERIF, java.awt.Font.PLAIN, newSize);

        // Update main window components
        setFont(zoomedFont);

        // Update tabbed pane
        if (conteneurOnglets != null) {
            conteneurOnglets.setFont(zoomedFont);

            // Update all query panels
            for (MyJPanelQuery panel : monTabOnglet) {
                if (panel != null) {
                    updatePanelZoom(panel, zoomedFont);
                }
            }

            // Update system panels
            if (ongletListener != null) {
                updateSystemPanelZoom(ongletListener, zoomedFont);
            }
            if (ongletShacl != null) {
                updateEditorZoom(ongletShacl, zoomedFont);
            }
            if (ongletTurtle != null) {
                updateEditorZoom(ongletTurtle, zoomedFont);
            }
        }

        // Update menu bar
        if (getJMenuBar() != null) {
            updateMenuZoom(getJMenuBar(), zoomedFont);
        }

        // Refresh the UI
        revalidate();
        repaint();
    }

    /** Update zoom for a query panel */
    private void updatePanelZoom(MyJPanelQuery panel, java.awt.Font font) {
        try {
            // Use reflection to update font if possible
            if (panel.getTextPaneQuery() != null) {
                panel.getTextPaneQuery().setFont(font);
            }
            // Update the panel itself
            panel.setFont(font);
            updateComponentTreeZoom(panel, font);
        } catch (Exception e) {
            LOGGER.debug("Could not update panel zoom: " + e.getMessage());
        }
    }

    /** Update zoom for system listener panel */
    private void updateSystemPanelZoom(MyJPanelListener panel, java.awt.Font font) {
        try {
            panel.setFont(font);
            if (panel.getTextPaneLogs() != null) {
                panel.getTextPaneLogs().setFont(font);
            }
            updateComponentTreeZoom(panel, font);
        } catch (Exception e) {
            LOGGER.debug("Could not update system panel zoom: " + e.getMessage());
        }
    }

    /** Update zoom for editor panels */
    private void updateEditorZoom(java.awt.Component editor, java.awt.Font font) {
        try {
            editor.setFont(font);
            updateComponentTreeZoom(editor, font);
        } catch (Exception e) {
            LOGGER.debug("Could not update editor zoom: " + e.getMessage());
        }
    }

    /** Update zoom for menu bar */
    private void updateMenuZoom(javax.swing.JMenuBar menuBar, java.awt.Font font) {
        try {
            menuBar.setFont(font);
            updateComponentTreeZoom(menuBar, font);
        } catch (Exception e) {
            LOGGER.debug("Could not update menu zoom: " + e.getMessage());
        }
    }

    /** Recursively update font for all components in a container */
    private void updateComponentTreeZoom(java.awt.Component component, java.awt.Font font) {
        try {
            component.setFont(font);
            if (component instanceof java.awt.Container) {
                java.awt.Container container = (java.awt.Container) component;
                for (java.awt.Component child : container.getComponents()) {
                    updateComponentTreeZoom(child, font);
                }
            }
        } catch (Exception e) {
            // Ignore errors during font update
        }
    }
}
// Test comment
