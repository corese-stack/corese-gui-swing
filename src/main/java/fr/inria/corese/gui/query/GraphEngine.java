package fr.inria.corese.gui.query;

import static fr.inria.corese.core.util.Property.Value.ACCESS_RIGHT;
import static fr.inria.corese.core.util.Property.Value.GRAPH_NODE_AS_DATATYPE;
import static fr.inria.corese.core.util.Property.Value.GUI_INDEX_MAX;
import static fr.inria.corese.core.util.Property.Value.LOAD_IN_DEFAULT_GRAPH;
import static fr.inria.corese.core.util.Property.Value.RDF_STAR;
import static fr.inria.corese.core.util.Property.Value.REENTRANT_QUERY;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.logging.Level;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import fr.inria.corese.core.Event;
import fr.inria.corese.core.Graph;
import fr.inria.corese.core.GraphStore;
import fr.inria.corese.core.api.Loader;
import fr.inria.corese.core.compiler.eval.QuerySolverVisitor;
import fr.inria.corese.core.kgram.core.Mappings;
import fr.inria.corese.core.load.Build;
import fr.inria.corese.core.load.Load;
import fr.inria.corese.core.load.LoadException;
import fr.inria.corese.core.query.QueryEngine;
import fr.inria.corese.core.query.QueryProcess;
import fr.inria.corese.core.rule.Cleaner;
import fr.inria.corese.core.rule.RuleEngine;
import fr.inria.corese.core.sparql.exceptions.EngineException;
import fr.inria.corese.core.sparql.triple.parser.ASTQuery;
import fr.inria.corese.core.sparql.triple.parser.Access;
import fr.inria.corese.core.sparql.triple.parser.Constant;
import fr.inria.corese.core.util.Parameter;
import fr.inria.corese.core.util.Property;
import fr.inria.corese.core.util.Tool;
import fr.inria.corese.gui.core.Command;

/**
 * Lite implementation of IEngine using kgraph and kgram
 *
 * @author Olivier Corby, Edelweiss, INRIA 2011
 */
public class GraphEngine {

    private static Logger logger = LogManager.getLogger(GraphEngine.class);

    private Graph graph;
    private RuleEngine rengine, owlEngine;
    private QueryEngine qengine;
    QueryProcess exec;
    private QuerySolverVisitor visitor;
    Build build;

    private boolean isListGroup = false, isDebug = false, linkedFunction = false;

    GraphEngine(boolean b) {
        graph = GraphStore.create(b);
        qengine = QueryEngine.create(graph);
        init();
    }

    void init() {
        exec = createQueryProcess();

        try {
            setVisitor(new QuerySolverVisitor(exec.getCreateEval()));
        } catch (EngineException ex) {
            java.util.logging.Logger.getLogger(GraphEngine.class.getName())
                    .log(Level.SEVERE, null, ex);
        }
    }

    /** Before creating a new Corese, tell the old one to finish */
    public void finish() {
        graph.getEventManager().process(Event.Finish);
    }

    public void init(Command cmd) {
        setOption(cmd);
        Property.init(getGraph());
    }

    public void setOption(Command cmd) {
        for (String key : cmd.keySet()) {
            logger.info("Command: " + key);
            switch (key) {
                case Command.VERBOSE:
                    graph.setVerbose(true);
                    break;
                case Command.METADATA:
                    graph.setMetadata(true);
                    break;

                case Command.LINKED_FUNCTION:
                    setLinkedFunction(true);
                    break;
                case Command.READ_FILE:
                    setReadFile(true);
                    break;

                case Command.STRING:
                    Constant.setString(true);
                    break;
                case Command.PARAM:
                    param(cmd.get(key));
                    break;

                case Command.LOAD:
                    logger.info("load: " + cmd.get(key));
                    loadDirProtect(cmd.get(key));
                    break;

                case Command.REENTRANT:
                    Property.set(REENTRANT_QUERY, true);
                    break;
                case Command.ACCESS:
                    Property.set(ACCESS_RIGHT, true);
                    break;
                case Command.LOAD_DEFAULT_GRAPH:
                    Property.set(LOAD_IN_DEFAULT_GRAPH, true);
                    break;
                case Command.NODE_AS_DATATYPE:
                    Property.set(GRAPH_NODE_AS_DATATYPE, true);
                case Command.RDF_STAR:
                    Property.set(RDF_STAR, true);
                    break;
            }
        }
    }

    void param(String path) {
        try {
            new Parameter().load(path).process();
            getVisitor().initServer("http://ns.inria.fr/corese/gui");
        } catch (LoadException ex) {
            logger.error(ex);
        }
    }

    public static GraphEngine create() {
        return new GraphEngine(true);
    }

    public static GraphEngine create(boolean rdfs) {
        return new GraphEngine(rdfs);
    }

    public void graphIndex() {
        int max = 10;
        if (Property.intValue(GUI_INDEX_MAX) != null) {
            max = Property.intValue(GUI_INDEX_MAX);
        }
        Graph g = getGraph();
        logger.info(g.display(max));
        logger.info(g.getNodeManager().display(max));
        logger.info(g.getIndex());
        Tool.trace("Memory used: %s", Tool.getMemoryUsageMegabytes());
    }

    public void definePrefix(String p, String ns) {
        QueryProcess.definePrefix(p, ns);
    }

    public void setListGroup(boolean b) {
        isListGroup = b;
    }

    public void setDebug(boolean b) {
        isDebug = b;
    }

    public Graph getGraph() {
        return graph;
    }

    public void cleanOWL() {
        try {
            Cleaner clean = new Cleaner(getGraph());
            clean.process();
        } catch (IOException | EngineException | LoadException ex) {
            logger.error(ex.getMessage());
        }
    }

    public QueryProcess createQueryProcess() {
        QueryProcess qp;

        logger.info("std dataset");
        qp = createBasicQueryProcess();

        return qp;
    }

    // graph dataset mode
    public QueryProcess createBasicQueryProcess() {
        QueryProcess qp = QueryProcess.create(graph, true);
        qp.setLoader(loader());
        qp.setListGroup(isListGroup);
        qp.setDebug(isDebug);
        return qp;
    }

    public Load loader() {
        Load load = Load.create(graph);
        load.setEngine(qengine);
        return load;
    }

    public void load(String path) throws EngineException, LoadException {
        Load ld = loader();
        ld.parse(path, ld.defaultGraph());
        // in case of load rule
        if (ld.getRuleEngine() != null) {
            setRuleEngine(ld.getRuleEngine());
        }
    }

    public void loadString(String rdf) throws EngineException, LoadException {
        Load ld = loader();
        ld.loadString(rdf, Loader.format.TURTLE_FORMAT);
    }

    public void loadDirProtect(String path) {
        try {
            Load ld = loader();
            if (path.contains(";")) {
                for (String name : path.split(";")) {
                    ld.parseDir(name);
                }
            } else {
                ld.parseDir(path);
            }
        } catch (LoadException ex) {
            logger.error(ex);
        }
    }

    public void loadDir(String path) throws EngineException, LoadException {
        load(path);
    }

    public boolean runRuleEngine() throws EngineException {
        return runRuleEngine(false, false);
    }

    public boolean runRuleEngine(boolean opt, boolean trace) throws EngineException {
        if (getRuleEngine() == null) {
            logger.error("No rulebase available yet");
            return false;
        }
        getRuleEngine().setDebug(isDebug);
        if (opt) {
            getRuleEngine().setSpeedUp(opt);
            getRuleEngine().setTrace(trace);
        }
        graph.process(getRuleEngine());
        return true;
    }

    public boolean runRule(String path) throws EngineException, LoadException {
        logger.info("Load rule: " + path);
        load(path);
        if (getRuleEngine() != null) {
            return getRuleEngine().process();
        }
        return true;
    }

    public void setOWLRL(int owl, boolean trace) throws EngineException {
        getOwlEngine().setProfile(owl);
        getOwlEngine().setTrace(trace);
        Date d1 = new Date();
        // disconnect RDFS entailment during OWL processing
        getOwlEngine().processWithoutWorkflow();
        Date d2 = new Date();
        logger.info("Time: " + (d2.getTime() - d1.getTime()) / (1000.0));
    }

    public void runQueryEngine() {
        try {
            qengine.process();
        } catch (EngineException ex) {
            logger.error(ex.getMessage());
        }
    }

    public boolean validate(String path) {

        return false;
    }

    public void loadRDF(String rdf, Loader.format format) throws EngineException, LoadException {

        InputStream stream = new ByteArrayInputStream(rdf.getBytes(StandardCharsets.UTF_8));

        Load ld = this.loader();
        ld.parse(stream, "", format);
    }

    // SPARQLProve functionality removed - obsolete implementation

    public Mappings SPARQLQuery(String query) throws EngineException {
        QueryExec exec = QueryExec.create(this);
        return exec.SPARQLQuery(query);
    }

    public Mappings query(String query) throws EngineException {
        QueryExec exec = QueryExec.create(this);
        return exec.query(query);
    }

    public Mappings update(String query) throws EngineException {
        QueryExec exec = QueryExec.create(this);
        return exec.update(query);
    }

    public Mappings SPARQLQuery(ASTQuery ast) throws EngineException {
        QueryExec exec = QueryExec.create(this);
        return exec.SPARQLQuery(ast);
    }

    public Mappings SPARQLQuery(String query, String[] from, String[] named)
            throws EngineException {
        QueryProcess exec = createQueryProcess();
        Mappings map = exec.query(query);
        return map;
    }

    public ASTQuery parse(String query) throws EngineException {
        return null;
    }

    public Mappings SPARQLQueryLoad(String query) throws EngineException {

        return null;
    }

    public boolean SPARQLValidate(String query) throws EngineException {

        return false;
    }

    /**
     * @deprecated
     */
    @Deprecated
    public void setProperty(String name, String value) {}

    public String getProperty(String name) {

        return null;
    }

    public String emptyResult(Mappings res) {

        return null;
    }

    public String getQuery(String uri) {

        return null;
    }

    public void start() {}

    /**
     * @return the visitor
     */
    public QuerySolverVisitor getVisitor() {
        return visitor;
    }

    /**
     * @param visitor the visitor to set
     */
    public void setVisitor(QuerySolverVisitor visitor) {
        this.visitor = visitor;
    }

    /**
     * @return the linkedFunction
     */
    public boolean isLinkedFunction() {
        return linkedFunction;
    }

    /**
     * @param linkedFunction the linkedFunction to set
     */
    public void setLinkedFunction(boolean linkedFunction) {
        this.linkedFunction = linkedFunction;
        Access.setLinkedFeature(linkedFunction);
    }

    public void setReadFile(boolean b) {
        Access.setReadFile(b);
    }

    public RuleEngine getRuleEngine(String path) {
        if (path == null) {
            return getOwlEngine();
        }
        return getRuleEngine();
    }

    public RuleEngine getOwlEngine() {
        return owlEngine;
    }

    public void setOwlEngine(RuleEngine owlEngine) {
        this.owlEngine = owlEngine;
    }

    public RuleEngine getRuleEngine() {
        return rengine;
    }

    public void setRuleEngine(RuleEngine rengine) {
        this.rengine = rengine;
    }
}
